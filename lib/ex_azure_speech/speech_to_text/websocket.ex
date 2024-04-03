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

  alias ExAzureSpeech.Auth.Client, as: AuthClient
  alias ExAzureSpeech.Common.{ConnectionState, HeaderNames, SocketMessage}
  alias ExAzureSpeech.Common.Errors.{InvalidMessage, InvalidResponse, Timeout}
  alias ExAzureSpeech.Common.Messages.{AudioMessage, SpeechConfigMessage}
  alias ExAzureSpeech.SpeechToText.{SocketConfig, SpeechContextConfig}

  alias ExAzureSpeech.SpeechToText.Errors.{
    FailedToSendMessage,
    SpeechRecognitionFailed,
    WebsocketConnectionNeverStarted
  }

  alias ExAzureSpeech.SpeechToText.Messages.SpeechContextMessage
  alias ExAzureSpeech.SpeechToText.Responses.SpeechPhrase

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
  @spec open_connection(SocketConfig.t()) :: {:ok, pid()} | {:error, any()}
  def open_connection(opts) do
    with connection_id <- opts[:connection_id],
         {:ok, token} <- AuthClient.auth(opts) do
      start_link(
        uri: SocketConfig.get_uri(opts),
        state: %ConnectionState{state: :connecting, connection_id: connection_id},
        opts: [
          headers: base_headers(opts, connection_id, token)
        ]
      )
    end
  end

  @doc """
  Synchronously processes the audio input and waits for the recognition response.
  """
  @spec process_and_wait(websocket_pid :: pid, audio :: Enumerable.t(), SpeechContextConfig.t()) ::
          {:ok, SpeechPhrase.t()}
          | {:error,
             WebsocketConnectionNeverStarted.t()
             | FailedToSendMessage.t()
             | InvalidMessage.t()
             | InvalidResponse.t()
             | SpeechRecognitionFailed.t()
             | Timeout.t()}
  def process_and_wait(pid, audio, opts) do
    with :ok <- websocket_started?(pid),
         {:ok, _} <- send_config_message(pid),
         {:ok, _} <- send_context_message(pid, opts),
         :ok <- stream_audio(pid, audio) do
      wait_for_response(pid)
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

  defp send_context_message(pid, opts) do
    {:ok, send(pid, {:command, SpeechContextMessage.new(opts)})}
  rescue
    _ -> {:error, FailedToSendMessage.exception(name: "SpeechContextMessage")}
  end

  defp stream_audio(pid, audio) do
    audio
    |> Stream.each(fn chunk ->
      send(pid, {:command, AudioMessage.new(chunk)})
    end)
    |> Stream.run()

    send(
      pid,
      {:command, AudioMessage.end_of_stream()}
    )

    :ok
  rescue
    _ -> {:error, FailedToSendMessage.exception(%{name: "AudioMessage"})}
  end

  defp wait_for_response(pid) do
    send(pid, {:command, :get_response, caller_pid: self()})

    receive do
      {:recognition, response} -> {:ok, response}
      {:error, reason} -> {:error, SpeechRecognitionFailed.exception(%{reason: reason})}
    after
      15_000 -> {:error, Timeout.exception(%{timeout: 15_000})}
    end
  end

  @doc false
  def handle_connect(_status, _headers, state) do
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
  def handle_info({:command, message}, state) do
    socket_message = SocketMessageProtocol.build_message(message, state.connection_id)

    {:ok, %ConnectionState{state | command_queue: :queue.in(socket_message, state.command_queue)}}
  end

  @doc false
  def handle_info(
        {:command, :get_response, caller_pid: from},
        %ConnectionState{response: nil} = state
      ) do
    {:ok, %ConnectionState{state | waiting_for_response: [from | state.waiting_for_response]}}
  end

  @doc false
  def handle_info(
        {:command, :get_response, caller_pid: from},
        %ConnectionState{response: response} = state
      ) do
    Enum.each(state.waiting_for_response ++ from, fn pid ->
      send(pid, response)
    end)

    {:ok, %ConnectionState{state | waiting_for_response: []}}
  end

  @doc false
  def handle_error(error, state) do
    Enum.each(state.waiting_for_response, fn pid ->
      send(pid, {:error, error})
    end)

    {:close, "Connection closed abnormally"}
  end

  @doc false
  def handle_control(_frame, state) do
    {:ok, state}
  end

  defp process_command(%SocketMessage{message_type: 0} = socket_message, state),
    do: {:reply, {:text, SocketMessage.serialize(socket_message)}, state}

  defp process_command(%SocketMessage{message_type: 1} = socket_message, state),
    do: {:reply, {:binary, SocketMessage.serialize(socket_message)}, state}

  defp process_command(
         {:internal, :notify_end},
         %ConnectionState{response: response} = state
       ) do
    Enum.each(state.waiting_for_response, fn pid ->
      send(pid, response)
    end)

    {:close, 1000, "Normal closure",
     %ConnectionState{state | state: :disconnected, waiting_for_response: []}}
  end

  defp handle_response(%SocketMessage{headers: headers} = message, state),
    do: handle_path(path_value(headers), message, state)

  defp handle_path("speech.startDetected", _message, state),
    do: {:ok, %ConnectionState{state | current_stage: :speech_start_detected}}

  defp handle_path("turn.start", _message, state),
    do: {:ok, %ConnectionState{state | current_stage: :turn_start}}

  defp handle_path("speech.hypothesis", _message, state),
    do: {:ok, %ConnectionState{state | current_stage: :speech_hypothesis}}

  defp handle_path("speech.endDetected", _message, state),
    do: {:ok, %ConnectionState{state | current_stage: :speech_end_detected}}

  defp handle_path("speech.phrase", message, state) do
    case Json.from_json(message.payload, SpeechPhrase) do
      {:ok, payload} ->
        {:ok,
         %ConnectionState{
           state
           | response: {:recognition, payload},
             current_stage: :speech_phrase
         }}

      {:error, err} ->
        {:ok,
         %ConnectionState{
           state
           | response: {:error, err},
             current_stage: :speech_phrase
         }}
    end
  end

  defp handle_path("turn.end", _message, state) do
    {:ok,
     %ConnectionState{
       state
       | state: :disconnecting,
         current_stage: :turn_end,
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

  defp base_headers(opts, connection_id, auth_token),
    do: [
      {HeaderNames.auth_key(), opts[:auth_key]},
      {HeaderNames.authorization(), "Bearer #{auth_token}"},
      {HeaderNames.connection_id(), connection_id}
    ]

  @doc false
  def child_spec(opts) do
    %{
      id: opts[:connection_id],
      start: {__MODULE__, :open_connection, [opts]}
    }
  end
end
