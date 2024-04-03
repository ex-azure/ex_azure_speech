defmodule ExAzureSpeech.Common.Messages.AudioMessage do
  @moduledoc """
  Represents an audio message to be sent over a socket. The audio itself can be streammed in chunks.  

  Path: audio  
  Content-Type: audio/x-wav or audio/ogg  
  MessageType: binary  

  Supported formats:  
  - WAV (with PCM 16-bit samples, 16 kHz sample rate, and a single channel).  
  - OGG (with Opus codec, 16 kHz sample rate, and a single channel).  
  """
  @moduledoc section: :common
  defstruct [:content, :size]

  alias __MODULE__

  @typedoc """
  content: The audio content chunk in a byte array format.
  size: The size of the audio content in bytes.
  """
  @type t() :: %AudioMessage{
          content: iodata(),
          size: non_neg_integer()
        }

  @doc """
  Creates a new audio message.
  """
  @spec new(iodata()) :: AudioMessage.t()
  def new(content),
    do: %AudioMessage{content: content, size: byte_size(content)}

  @doc """
  Creates an audio message with no body, this is used to signal the end of the audio stream.
  """
  @spec end_of_stream() :: AudioMessage.t()
  def end_of_stream(),
    do: %AudioMessage{content: "", size: 0}

  defimpl ExAzureSpeech.Common.Protocols.SocketMessage,
    for: AudioMessage do
    alias ExAzureSpeech.Common.{Guid, HeaderNames, SocketMessage}
    alias ExAzureSpeech.Common.Messages.MessageType

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
