defmodule ExAzureSpeech.SpeechToText.Websocket do
  @moduledoc """
  Websocket Connection with the Azure Cognitive Services Speech-to-Text service.  

  The SpeechSDK internals is straightforward and works like this:

  1. Open a websocket connection to the Azure Cognitive Services Speech-to-Text service.
  2. The client sends a `ExAzureSpeech.Common.Messages.SpeechConfigMessage` informing the basic configuration for the recognition.
  3. The client sends a `ExAzureSpeech.SpeechToText.Messages.SpeechContextMessage` to configure the context of the recognition, with language,
  if it should run a pronunciation assessment and so on.
  4. The Server process the data and answers with a speech.startDetected followed by a turn.start message, indicating that its ready to receive the audio input.
  5. The client sends the audio input in chunks using the `ExAzureSpeech.Common.Messages.AudioMessage` message.
  6. The client sends a `ExAzureSpeech.Common.Messages.AudioMessage.end_of_stream` message to indicate the end of the audio input. (optional)
  7. The client waits for the recognition response, which is a JSON object with the recognition result and optionally the pronunciation assessment.
  8. The server sends a speech.endDetected message followed by a turn.end message, indicating that the recognition is over.
  """
  @moduledoc section: :speech_to_text
  use Fresh

  require WaitForIt
  require Logger

  alias ExAzureSpeech.Common.Guid
  alias ExAzureSpeech.Auth.Client, as: AuthClient
  alias ExAzureSpeech.Common.{ConnectionState, HeaderNames, SocketMessage}
  alias ExAzureSpeech.Common.Errors.{InvalidMessage, InvalidResponse, Timeout}
  alias ExAzureSpeech.Common.Messages.{AudioMessage, SpeechConfigMessage}
  alias ExAzureSpeech.Common.ReplayableAudioStream
  alias ExAzureSpeech.SpeechToText.{SocketConfig, SpeechContextConfig}

  alias ExAzureSpeech.SpeechToText.Errors.{
    FailedToSendMessage,
    SpeechRecognitionFailed,
    WebsocketConnectionNeverStarted
  }

  alias ExAzureSpeech.SpeechToText.Messages.SpeechContextMessage
  alias ExAzureSpeech.SpeechToText.Responses.{EndDetected, SpeechPhrase}

  alias ExAzureSpeech.Common.Protocols.Json

  alias ExAzureSpeech.Common.Protocols.SocketMessage,
    as: SocketMessageProtocol

  @typedoc """
  All possible responses from the Azure Cognitive Services Speech-to-Text service.  

  speech_start_detected: The server accepted the speech configs and contexts and will start a recognition turn.  
  turn_start: The server started a recognition turn and is waiting for audio input.  
  speech_hypothesis: The server is processing the audio input and has a hypothesis already processed  
  speech_end_detected: The server detected the end of the speech input and will return the final results.  
  speech_phrase: The server has a recognition result.  
  turn_end: The server ended the recognition turn and the connection is ready for a new recognition turn or to being closed.  
  """
  @type expected_responses() ::
          :speech_start_detected
          | :turn_start
          | :speech_hypothesis
          | :speech_end_detected
          | :speech_phrase
          | :turn_end

  @doc """
  Opens a WebSocket connection with the Azure Cognitive Services Speech-to-Text service.
  """
  @spec open_connection(SocketConfig.t(), SpeechContextConfig.t(), Enumerable.t()) ::
          {:ok, pid()} | {:error, any()}
  def open_connection(opts, context_config, stream) do
    with connection_id <- opts[:connection_id],
         context <- SpeechContextMessage.new(context_config),
         {:ok, token} <- AuthClient.auth(opts) do
      start_link(
        uri: SocketConfig.get_uri(opts),
        state: %ConnectionState{
          state: :connecting,
          connection_id: connection_id,
          context: context,
          last_received_message_timestamp: DateTime.utc_now(),
          audio_stream: %ReplayableAudioStream{
            buffer: <<>>,
            stream: stream,
            buffer_offset: 0,
            last_read_offset: 0,
            bytes_per_second: 16_000 * 16 / 8,
            chunk_size: 32_768
          }
        },
        opts: [
          headers: base_headers(opts, connection_id, token),
          info_logging: false
        ]
      )
    end
  end

  @spec process_to_stream(websocket_pid :: pid, socket_close_function :: any()) ::
          {:ok, Enumerable.t()}
          | {:error,
             WebsocketConnectionNeverStarted.t()
             | FailedToSendMessage.t()
             | InvalidMessage.t()
             | InvalidResponse.t()
             | SpeechRecognitionFailed.t()
             | Timeout.t()}
  def process_to_stream(pid, deferred_session_close) do
    with :ok <- websocket_started?(pid),
         {:ok, _} <- send_config_message(pid),
         {:ok, _} <- update_connection_context(pid),
         {:ok, _} <- start_stream(pid) do
      {:ok, stream_responses(pid, deferred_session_close)}
    else
      {:error, _} = error ->
        deferred_session_close.(pid)
        error
    end
  end

  defp websocket_started?(pid) do
    # This is a workaround to wait for the WebSocket connection to be ready, the Fresh websocket framework often returns an :ok before the connection is ready.
    # This hooks a custom property in the process dictionary for us to explicitly check once the connection is ready.
    WaitForIt.case_wait Keyword.get(Process.info(pid)[:dictionary], :socket_state),
      frequency: 100,
      timeout: 5_000 do
      :ready -> :ok
    else
      _ -> {:error, WebsocketConnectionNeverStarted.exception()}
    end
  end

  defp send_config_message(pid) do
    {:ok, send(pid, {:command, SpeechConfigMessage.new()})}
  rescue
    _ -> {:error, FailedToSendMessage.exception(%{name: "SpeechConfigMessage"})}
  end

  defp update_connection_context(pid) do
    {:ok, send(pid, {:command, :update_connection_context})}
  rescue
    _ -> {:error, FailedToSendMessage.exception(name: "UpdateConnectionContext")}
  end

  defp start_stream(pid) do
    {:ok, send(pid, {:command, :stream_audio})}
  rescue
    _ -> {:error, FailedToSendMessage.exception(name: "AudioMessage")}
  end

  defp stream_responses(pid, deferred_function_close) do
    Stream.resource(
      fn ->
        []
      end,
      fn _ ->
        send(pid, {:command, :get_response, caller_pid: self()})

        receive do
          :end_of_recognition -> {:halt, []}
          :empty -> {[], []}
          {:recognition, response} -> {[response], []}
          {:error, _reason} -> {[], []}
        end
      end,
      fn _ -> deferred_function_close.(pid) end
    )
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
  def handle_in({:binary, _frame}, state) do
    {:ok, state}
  end

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
  def handle_info(
        {:command, :stream_audio},
        %ConnectionState{} = state
      ) do
    case read_audio_chunk(state) do
      {%{size: 0} = chunk, new_state} ->
        handle_info({:command, chunk}, new_state)

      {chunk, new_state} ->
        Process.send_after(self(), {:command, :stream_audio}, 10)
        handle_info({:command, chunk}, new_state)
    end
  end

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
  def handle_error(error, state) do
    Logger.error(
      "[ExAzureSpeech] Error processing Speech-to-Text, cause: #{inspect(error)}",
      connection_id: state.connection_id
    )

    Enum.each(state.waiting_for_response, fn pid ->
      send(pid, {:error, error})
    end)

    {:close, "Connection closed abnormally"}
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
           responses: state.responses ++ [:end_of_recognition]
       }}
    else
      {:ok, state}
    end
  end

  def handle_terminate(reason, state) do
    Logger.debug(
      "[ExAzureSpeech] Terminating the connection with reason '#{inspect(reason)}'",
      connection_id: state.connection_id
    )

    {:close, 1000, "Connection closed by the client"}
  end

  def handle_disconnect(code, reason, state) do
    Logger.error(
      "[ExAzureSpeech] Disconnected from the Azure Cognitive Services Speech-to-Text service with code '#{code}' and reason '#{reason}'",
      connection_id: state.connection_id
    )

    {:close, reason}
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
           | responses: state.responses ++ [:end_of_recognition]
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

  defp handle_path("speech.startDetected", _message, state),
    do: {:ok, %ConnectionState{state | current_stage: :speech_start_detected}}

  defp handle_path("turn.start", _message, state) do
    Process.send_after(self(), {:command, :stream_audio}, 100)
    {:ok, %ConnectionState{state | current_stage: :turn_start}}
  end

  defp handle_path("speech.hypothesis", _message, state),
    do: {:ok, %ConnectionState{state | current_stage: :speech_hypothesis}}

  defp handle_path("speech.endDetected", message, state) do
    case Json.from_json(message.payload, EndDetected) do
      {:ok, payload} ->
        {:ok, set_new_offset(payload.offset, state)}

      {:error, err} ->
        {:ok,
         %ConnectionState{
           state
           | responses: [{:error, err}],
             current_stage: :speech_end_detected
         }}
    end
  end

  defp handle_path("speech.phrase", message, state) do
    case Json.from_json(message.payload, SpeechPhrase) do
      {:ok, payload} ->
        {:ok,
         %ConnectionState{
           state
           | responses: [{:recognition, payload}],
             current_stage: :speech_phrase
         }}

      {:error, err} ->
        {:ok,
         %ConnectionState{
           state
           | responses: [{:error, err}],
             current_stage: :speech_phrase
         }}
    end
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

  defp set_new_offset(new_offset, %ConnectionState{} = state)
       when new_offset >= state.audio_stream.buffer_offset,
       do: %ConnectionState{
         state
         | state: :disconnecting,
           current_stage: :speech_end_detected
       }

  defp set_new_offset(new_offset, state),
    do: %ConnectionState{
      state
      | current_stage: :speech_end_detected,
        audio_stream:
          %ReplayableAudioStream{state.audio_stream | buffer_offset: new_offset}
          |> ReplayableAudioStream.shrink()
    }

  defp read_audio_chunk(%ConnectionState{audio_stream: audio_stream} = state) do
    case ReplayableAudioStream.read(audio_stream) do
      {:ok, {chunk, audio_stream}} when chunk != :eof ->
        {AudioMessage.new(chunk), %ConnectionState{state | audio_stream: audio_stream}}

      {:ok, {:eof, audio_stream}} ->
        {AudioMessage.end_of_stream(), %ConnectionState{state | audio_stream: audio_stream}}
    end
  end

  defp path_value(headers),
    do:
      Enum.find_value(headers, nil, fn [header, value] ->
        if header == HeaderNames.path(), do: value
      end)

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
