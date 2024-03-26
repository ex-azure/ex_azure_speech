defmodule ExAzureCognitiveServicesSpeechSdk.PronunciationAssessment.Websocket do
  use Fresh

  alias ExAzureCognitiveServicesSpeechSdk.Auth.Client, as: AuthClient
  alias ExAzureCognitiveServicesSpeechSdk.Common.ConnectionState
  alias ExAzureCognitiveServicesSpeechSdk.Common.HeaderNames
  alias ExAzureCognitiveServicesSpeechSdk.Common.SocketMessage
  alias ExAzureCognitiveServicesSpeechSdk.Common.Messages.SpeechConfigMessage
  alias ExAzureCognitiveServicesSpeechSdk.Common.Messages.AudioMessage
  alias ExAzureCognitiveServicesSpeechSdk.PronunciationAssessment.SocketConfig
  alias ExAzureCognitiveServicesSpeechSdk.PronunciationAssessment.Messages.SpeechContextMessage

  alias ExAzureCognitiveServicesSpeechSdk.Common.Protocols.SocketMessage,
    as: SocketMessageProtocol

  def open_connection(connection_id, opts) do
    {:ok, token} = AuthClient.auth(opts)

    start_link(
      uri: SocketConfig.get_uri(opts),
      state: %ConnectionState{state: :connecting, connection_id: connection_id},
      opts: [
        name: {:local, connection_id},
        headers: base_headers(opts, connection_id, token)
      ]
    )
  end

  def recognize_once(connection_id, file_path, reference_text, opts \\ []) do
    with :ok <- send_context_message(connection_id, reference_text, opts),
         :ok <- stream_audio_file(connection_id, file_path) do
      receive do
        {:ok, {:assessment, assessment}} -> {:ok, assessment}
        {:error, {:assessment, error}} -> {:error, error}
      after
        5_000 -> {:error, :timeout}
      end
    end
  end

  defp send_context_message(connection_id, reference_text, opts) do
    case SpeechContextMessage.new(reference_text, opts) do
      {:ok, command} ->
        send(connection_id, {:internal, command, pid: self()})

      {:error, _} ->
        {:error, "Invalid context message"}
    end
  end

  defp stream_audio_file(connection_id, file_path) do
    File.stream!(file_path, 2048)
    |> Stream.each(fn chunk ->
      send(connection_id, {:internal, AudioMessage.new(chunk), pid: self()})
    end)
    |> Stream.run()

    send(connection_id, {:internal, AudioMessage.end_of_stream(), pid: self()})
  end

  def handle_connect(_status, _headers, state) do
    config_message =
      SpeechConfigMessage.new()
      |> SocketMessageProtocol.build_message(state.connection_id)
      |> SocketMessage.serialize()

    {:reply, {:text, config_message}, %ConnectionState{state | state: :connected}}
  end

  def handle_in({:binary, _frame}, state) do
    {:ok, state}
  end

  def handle_in({:text, frame}, state),
    do:
      SocketMessage.deserialize(:text, frame)
      |> handle_response(state)

  def handle_info({:internal, %SpeechContextMessage{} = message}, state) do
    context_message =
      SocketMessageProtocol.build_message(message, state.connection_id)
      |> SocketMessage.serialize()

    {:reply, {:text, context_message}, state}
  end

  def handle_info({:internal, %AudioMessage{} = message}, state) do
    audio_message =
      SocketMessageProtocol.build_message(message, state.connection_id)
      |> SocketMessage.serialize()

    {:reply, {:binary, audio_message}, state}
  end

  def handle_error(_error, _state) do
    :close
  end

  def handle_control(_frame, state) do
    {:ok, state}
  end

  defp handle_response(%SocketMessage{headers: headers} = message, state) do
    dbg(message)

    case path_value(headers) do
      "speech.phrase" -> {:ok, state}
      "speech.hypothesis" -> {:ok, state}
      "speech.startdetected" -> {:ok, state}
      "speech.enddetected" -> {:ok, state}
      nil -> {:ok, state}
    end
  end

  defp path_value(headers),
    do:
      Enum.find_value(headers, nil, fn {header, value} ->
        if header == HeaderNames.path(), do: value
      end)

  defp base_headers(opts, connection_id, auth_token),
    do: [
      {HeaderNames.auth_key(), opts[:auth_key]},
      {HeaderNames.authorization(), "Bearer #{auth_token}"},
      {HeaderNames.connection_id(), connection_id}
    ]
end
