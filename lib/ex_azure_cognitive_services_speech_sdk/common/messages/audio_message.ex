defmodule ExAzureCognitiveServicesSpeechSdk.Common.Messages.AudioMessage do
  defstruct [:content, :size]

  alias __MODULE__

  @type t :: %AudioMessage{
          content: iodata(),
          size: non_neg_integer()
        }

  @spec new(iodata()) :: t()
  def new(content),
    do: %AudioMessage{content: content, size: byte_size(content)}

  @spec end_of_stream() :: t()
  def end_of_stream(),
    do: %AudioMessage{content: "", size: 0}

  defimpl ExAzureCognitiveServicesSpeechSdk.Common.Protocols.SocketMessage,
    for: AudioMessage do
    alias ExAzureCognitiveServicesSpeechSdk.Common.{Guid, HeaderNames, SocketMessage}
    alias ExAzureCognitiveServicesSpeechSdk.Common.Messages.MessageType

    def build_message(payload, id) do
      %SocketMessage{
        id: Guid.create_no_dash_guid(),
        message_type: MessageType.binary(),
        payload: payload.content,
        headers: [
          {HeaderNames.path(), "audio"},
          {HeaderNames.request_id(), id},
          {HeaderNames.request_timestamp(), DateTime.utc_now() |> DateTime.to_iso8601()},
          {HeaderNames.content_type(), "audio/x-wav"}
        ]
      }
    end
  end
end
