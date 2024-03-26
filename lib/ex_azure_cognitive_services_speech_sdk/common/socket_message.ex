defmodule ExAzureCognitiveServicesSpeechSdk.Common.SocketMessage do
  defstruct [
    :id,
    :payload,
    :message_type,
    :headers
  ]

  alias __MODULE__

  alias ExAzureCognitiveServicesSpeechSdk.Common.Messages.MessageType
  alias ExAzureCognitiveServicesSpeechSdk.Common.Guid

  @type t() :: %SocketMessage{
          id: Guid.t(),
          payload: binary(),
          message_type: MessageType.t(),
          headers: list({String.t(), String.t()})
        }

  def serialize(%SocketMessage{message_type: 0} = socket_message),
    do: serialize_headers(socket_message.headers) <> "\r\n\r\n" <> socket_message.payload

  def serialize(%SocketMessage{message_type: 1} = socket_message) do
    headers = serialize_headers(socket_message.headers)
    headers_length = byte_size(headers)
    payload = socket_message.payload

    <<headers_length::big-16, headers::binary, payload::binary>>
  end

  def deserialize(:text, text) do
    [headers, payload] = String.split(text, "\r\n\r\n")
    headers = String.split(headers, "\r\n")

    %SocketMessage{
      headers: Enum.map(headers, fn header -> String.split(header, ":", parts: 2) end),
      payload: payload,
      message_type: 0
    }
  end

  defp serialize_headers(headers),
    do: Enum.map_join(headers, "\r\n", fn {key, value} -> "#{key}:#{value}" end)
end
