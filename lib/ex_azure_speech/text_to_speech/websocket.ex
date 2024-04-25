defmodule ExAzureSpeech.TextToSpeech.Websocket do
  @moduledoc """
  Module for handling the websocket connection to the Azure Text to Speech service.  

  The Text-to-Speech webhook internals are implemented like this:  

  1. Opens a WebSocket connection to the Azure Text to Speech service.  
  2. The client sends a `ExAzureSpeech.Common.Messages.SpeechConfigMessage` informing the basic configuration for the recognition.  
  3. The client sends a `ExAzureSpeech.TextToSpeech.Messages.SynthesisContextMessage` informing the synthesis context.  
  4. The client sends a `ExAzureSpeech.TextToSpeech.Messages.SynthesisMessage` to start the synthesis.  
  5. The client receives audio metadata from the service. Which can be processed by the asynchronous callbacks  
  6. The client receives audio data from the service in a binary format  
  7. The client receives a `ExAzureSpeech.TextToSpeech.Responses.AudioMetadata.session_end` message when the synthesis ends.  
  """
  @moduledoc section: :text_to_speech
  use Fresh

  require WaitForIt
  require Logger

  alias ExAzureSpeech.Auth.Client, as: AuthClient
  alias ExAzureSpeech.Auth.Errors, as: AuthError

  alias ExAzureSpeech.Common.{ConnectionState, Guid, HeaderNames}
  alias ExAzureSpeech.Common.Messages.SpeechConfigMessage
  alias ExAzureSpeech.Common.Protocols.SocketMessage, as: SocketMessageProtocol
  alias ExAzureSpeech.Common.Protocols.Json
  alias ExAzureSpeech.Common.SocketMessage

  alias ExAzureSpeech.Common.Errors.{
    FailedToDispatchCommand,
    WebsocketConnectionFailed,
    Internal
  }

  alias ExAzureSpeech.TextToSpeech.Messages.{SynthesisContextMessage, SynthesisMessage}
  alias ExAzureSpeech.TextToSpeech.Responses.AudioMetadata
  alias ExAzureSpeech.TextToSpeech.{SocketConfig, SpeechSynthesisConfig}

  @default_callbacks [
    viseme_callback: &Function.identity/1,
    word_boundary_callback: &Function.identity/1,
    sentence_boundary_callback: &Function.identity/1,
    session_end_callback: &Function.identity/1
  ]

  @typedoc """
  Callbacks for handling audio metadata.  

  viseme_callback: Executes everytime an Viseme metadata is received.  
  word_boundary_callback: Executes everytime an Word Boundary metadata is received.  
  sentence_boundary_callback: Executes everytime an Sentence Boundary metadata is received.  
  session_end_callback: Executes everytime an Session End metadata is received.  
  """
  @type callbacks() :: [
          viseme_callback: (AudioMetadata.viseme() -> any()),
          word_boundary_callback: (AudioMetadata.word_boundary() -> any()),
          sentence_boundary_callback: (AudioMetadata.sentence_boundary() -> any()),
          session_end_callback: (AudioMetadata.session_end() -> any())
        ]

  @typedoc """
  Expected websocket frame responses from the Azure Text-to-Speech Service.  

  turn_start: The start of a new synthesis turn.  
  response: Returns info from a stream, nothing useful.--
  audio_metadata: Returns metadata about the audio. Like boundaries, visemes, etc.  
  audio: Returns the audio data in binary format.  
  turn_end: The end of a synthesis turn.
  """
  @type expected_responses() ::
          :turn_start
          | :response
          | :audio_metadata
          | :audio
          | :turn_end

  @doc """
  Opens a connection to the Azure Text to Speech service.
  """
  @spec open_connection(SocketConfig.t(), SpeechSynthesisConfig.t(), callbacks()) ::
          {:ok, pid()} | {:error, AuthError.Unauthorized.t() | AuthError.Failure.t()}
  def open_connection(opts, context, callbacks) do
    with connection_id <- opts[:connection_id],
         message <- SynthesisContextMessage.new(context),
         callbacks <- Keyword.merge(@default_callbacks, callbacks),
         {:ok, token} <- AuthClient.auth(opts) do
      start_link(
        uri: SocketConfig.get_uri(opts),
        state: %ConnectionState{
          state: :connecting,
          connection_id: connection_id,
          context: message,
          callbacks: callbacks,
          last_received_message_timestamp: DateTime.utc_now()
        },
        opts: [
          headers: base_headers(opts, connection_id, token),
          info_logging: false
        ]
      )
    end
  end

  @doc """
  Synthesises the given text using the Azure Text to Speech service.
  """
  @spec synthesize(pid(), SynthesisMessage.t(), (pid() -> any())) ::
          {:ok, Enumerable.t()} | {:error, term()}
  def synthesize(pid, command, close_connection_callback) do
    with :ok <- websocket_started?(pid),
         {:ok, _} <- send_config_message(pid),
         {:ok, _} <- update_connection_context(pid),
         {:ok, _} <- start_synthesis(pid, command) do
      {:ok, stream_responses(pid, close_connection_callback)}
    end
  end

  defp start_synthesis(pid, command) do
    {:ok, send(pid, {:command, command})}
  rescue
    _ ->
      {:error, FailedToDispatchCommand.exception(command: :start_synthesis, websocket_pid: pid)}
  end

  defp stream_responses(pid, close_connection_callback) do
    Stream.resource(
      fn ->
        []
      end,
      fn _ ->
        send(pid, {:command, :get_response, caller_pid: self()})

        receive do
          :empty ->
            {[], []}

          :end_of_synthesis ->
            {:halt, []}

          {:synthesis, response} ->
            {[response.payload], []}

          {:error, reason} ->
            {:halt, reason}
        end
      end,
      fn _ -> close_connection_callback.(pid) end
    )
  end

  defp websocket_started?(pid) do
    WaitForIt.case_wait Keyword.get(Process.info(pid)[:dictionary], :socket_state),
      frequency: 100,
      timeout: 5_000 do
      :ready -> :ok
    else
      _ -> {:error, WebsocketConnectionFailed.exception()}
    end
  end

  defp send_config_message(pid) do
    {:ok, send(pid, {:command, SpeechConfigMessage.new()})}
  rescue
    _ ->
      {:error,
       FailedToDispatchCommand.exception(command: SpeechConfigMessage, websocket_pid: pid)}
  end

  defp update_connection_context(pid) do
    {:ok, send(pid, {:command, :update_connection_context})}
  rescue
    _ ->
      {:error,
       FailedToDispatchCommand.exception(command: :update_connection_context, websocket_pid: pid)}
  end

  @doc false
  def handle_connect(_status, _headers, state) do
    Logger.debug(
      "[ExAzureSpeech] Connected to the Azure Cognitive Services Speech-to-Text service",
      connection_id: state.connection_id
    )

    Process.put(:socket_state, :ready)
    Process.send_after(self(), {:internal, :event_loop}, 1)
    {:ok, %ConnectionState{state | state: :connected}}
  end

  @doc false
  def handle_in({:binary, frame}, state),
    do:
      SocketMessage.deserialize(:binary, frame)
      |> handle_response(state)

  @doc false
  def handle_in({:text, frame}, state),
    do:
      SocketMessage.deserialize(:text, frame)
      |> handle_response(state)

  @doc false
  def handle_info(
        {:internal, :event_loop},
        %ConnectionState{} = state
      ) do
    case :queue.out(state.command_queue) do
      {:empty, command_queue} ->
        send(self(), {:internal, :event_loop})
        {:ok, %ConnectionState{state | command_queue: command_queue}}

      {{:value, command}, command_queue} ->
        send(self(), {:internal, :event_loop})
        process_command(command, %ConnectionState{state | command_queue: command_queue})
    end
  end

  @doc false
  def handle_info(
        {:command, :update_connection_context},
        %ConnectionState{} = state
      ),
      do: handle_info({:command, state.context}, state)

  @doc false
  def handle_info({:command, message}, state) do
    Logger.debug(
      "[ExAzureSpeech] Sending request '#{inspect(message)}'",
      connection_id: state.connection_id
    )

    socket_message = SocketMessageProtocol.build_message(message, state.connection_id)

    {:ok, %ConnectionState{state | command_queue: :queue.in(socket_message, state.command_queue)}}
  end

  @doc false
  def handle_info(
        {:command, :get_response, caller_pid: from},
        %ConnectionState{responses: []} = state
      ) do
    send(from, :empty)
    {:ok, state}
  end

  @doc false
  def handle_info(
        {:command, :get_response, caller_pid: from},
        %ConnectionState{responses: responses} = state
      ) do
    Enum.each(responses, fn response ->
      send(from, response)
    end)

    {:ok, %ConnectionState{state | responses: []}}
  end

  @doc false
  def handle_control(frame, state) do
    Logger.debug(
      "[ExAzureSpeech] Received control frame '#{inspect(frame)}'",
      connection_id: state.connection_id
    )

    if DateTime.diff(state.last_received_message_timestamp, DateTime.utc_now(), :second) > 5 do
      Logger.warning(
        "[ExAzureSpeech] No more data received from the recognition service, disconnecting...",
        connection_id: state.connection_id
      )

      {:ok,
       %ConnectionState{
         state
         | state: :disconnecting,
           responses: state.responses ++ [:end_of_synthesis]
       }}
    else
      {:ok, state}
    end
  end

  @doc false
  def handle_terminate(reason, state) do
    Logger.debug(
      "[ExAzureSpeech] Terminating the connection with reason '#{inspect(reason)}'",
      connection_id: state.connection_id
    )

    {:close, 1000, "Connection closed by the client"}
  end

  @doc false
  def handle_disconnect(code, reason, state) do
    Logger.error(
      "[ExAzureSpeech] Disconnected from the Azure Cognitive Services Text-to-Speech service with code '#{code}' and reason '#{reason}'",
      connection_id: state.connection_id
    )

    {:reconnect,
     %ConnectionState{
       state
       | responses: state.responses ++ [{:error, Internal.exception(reason)}]
     }}
  end

  defp process_command(%SocketMessage{message_type: 0} = socket_message, state),
    do: {:reply, {:text, SocketMessage.serialize(socket_message)}, state}

  defp process_command(%SocketMessage{message_type: 1} = socket_message, state),
    do: {:reply, {:binary, SocketMessage.serialize(socket_message)}, state}

  defp process_command(
         {:internal, :notify_end},
         %ConnectionState{state: :disconnecting} = state
       ),
       do:
         handle_info({:command, state.context}, %ConnectionState{
           state
           | responses: state.responses ++ [:end_of_synthesis]
         })

  defp process_command(
         {:internal, :notify_end},
         %ConnectionState{} = state
       ),
       do:
         handle_info({:command, state.context}, %ConnectionState{
           state
           | connection_id: Guid.create_no_dash_guid()
         })

  defp handle_response(%SocketMessage{headers: headers} = message, state) do
    path = path_value(headers)

    Logger.debug(
      "[ExAzureSpeech][path: #{path}] Received response '#{inspect(message)}'",
      connection_id: state.connection_id
    )

    handle_path(path, message, %ConnectionState{
      state
      | last_received_message_timestamp: DateTime.utc_now()
    })
  end

  defp handle_path("turn.start", _message, state) do
    {:ok, %ConnectionState{state | current_stage: :turn_start}}
  end

  defp handle_path("response", _message, state) do
    {:ok, %ConnectionState{state | current_stage: :response}}
  end

  defp handle_path("audio.metadata", message, state) do
    case Json.from_json(message.payload, AudioMetadata) do
      {:ok, payload} ->
        handle_callback(payload, state)

        {:ok,
         %ConnectionState{
           state
           | current_stage: :audio_metadata
         }}

      {:error, err} ->
        {:ok,
         %ConnectionState{
           state
           | responses: [{:error, err}],
             current_stage: :audio_metadata
         }}
    end
  end

  defp handle_path("audio", %SocketMessage{payload: ""}, state) do
    {:ok,
     %ConnectionState{
       state
       | current_stage: :audio,
         state: :disconnecting
     }}
  end

  defp handle_path("audio", message, state) do
    {:ok,
     %ConnectionState{
       state
       | responses: state.responses ++ [{:synthesis, message}],
         current_stage: :audio
     }}
  end

  defp handle_path("turn.end", _message, state) do
    {:ok,
     %ConnectionState{
       state
       | current_stage: :turn_end,
         command_queue: :queue.in({:internal, :notify_end}, state.command_queue)
     }}
  end

  defp handle_path(_unknown, _message, state),
    do: {:ok, state}

  defp path_value(headers),
    do:
      Enum.find_value(headers, nil, fn [header, value] ->
        if header == HeaderNames.path(), do: value
      end)

  defp handle_callback(
         %AudioMetadata{metadata: [%{type: "Viseme"}]} = metadata,
         %ConnectionState{callbacks: callbacks}
       ) do
    result = callbacks[:viseme_callback].(metadata)
    Logger.debug("[ExAzureSpeech] Viseme callback result: '#{inspect(result)}'")

    :ok
  end

  defp handle_callback(
         %AudioMetadata{metadata: [%{type: "SentenceBoundary"}]} = metadata,
         %ConnectionState{callbacks: callbacks}
       ) do
    result = callbacks[:sentence_boundary_callback].(metadata)
    Logger.debug("[ExAzureSpeech] SentenceBoundary callback result: '#{inspect(result)}'")

    :ok
  end

  defp handle_callback(
         %AudioMetadata{metadata: [%{type: "WordBoundary"}]} = metadata,
         %ConnectionState{callbacks: callbacks}
       ) do
    result = callbacks[:word_boundary_callback].(metadata)
    Logger.debug("[ExAzureSpeech] WordBoundary callback result: '#{inspect(result)}'")

    :ok
  end

  defp handle_callback(
         %AudioMetadata{metadata: [%{type: "SessionEnd"}]} = metadata,
         %ConnectionState{callbacks: callbacks}
       ) do
    result = callbacks[:session_end_callback].(metadata)
    Logger.debug("[ExAzureSpeech] SessionEnd callback result: '#{inspect(result)}'")

    :ok
  end

  defp handle_callback(
         metadata,
         _
       ) do
    Logger.warning("[ExAzureSpeech] Unknown metadata type: '#{inspect(metadata)}'")

    :ok
  end

  defp base_headers(opts, connection_id, auth_token),
    do: [
      {HeaderNames.auth_key(), opts[:auth_key]},
      {HeaderNames.authorization(), "Bearer #{auth_token}"},
      {HeaderNames.connection_id(), connection_id}
    ]

  @doc false
  def child_spec({socket_opts, context_opts, stream}) do
    %{
      id: socket_opts[:connection_id],
      start: {__MODULE__, :open_connection, [socket_opts, context_opts, stream]}
    }
  end
end
