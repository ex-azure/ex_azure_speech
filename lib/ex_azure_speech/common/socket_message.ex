defmodule ExAzureSpeech.Common.SocketMessage do
  @moduledoc """
  Represents a message to be sent through the WebSocket.
  """
  @moduledoc section: :common
  defstruct [
    :id,
    :payload,
    :message_type,
    :headers
  ]

  alias __MODULE__

  alias ExAzureSpeech.Common.Messages.MessageType
  alias ExAzureSpeech.Common.Guid

  @typedoc """
  id: Non-Dashered GUID for the message.  
  payload:The message payload, it can be a binary or a text.  
  message_type: The type of the message.  
  headers: List of headers for the message.  
  """
  @type t() :: %SocketMessage{
          id: Guid.t() | nil,
          payload: binary(),
          message_type: MessageType.t(),
          headers: list({String.t(), String.t()})
        }

  @doc """
  Serializers a SocketMessage to the expected websocket format.  

  Text messages are serialized as headers followed by a double line break and the payload.  
  Binary messages are serialized as a 16-bit big-endian integer representing the length of the headers, followed by the headers and the payload.  
  """
  @spec serialize(SocketMessage.t()) :: binary() | iodata()
  def serialize(%SocketMessage{message_type: 0} = socket_message),
    do: serialize_headers(socket_message.headers) <> "\r\n\r\n" <> socket_message.payload

  def serialize(%SocketMessage{message_type: 1} = socket_message) do
    headers = serialize_headers(socket_message.headers)
    headers_length = byte_size(headers)
    payload = socket_message.payload

    <<headers_length::big-16, headers::binary, payload::binary>>
  end

  @doc """
  Deserializes a text message into a SocketMessage.
  """
  @spec deserialize(:text, binary()) :: SocketMessage.t()
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
