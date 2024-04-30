defmodule ExAzureSpeech.TextToSpeech.Messages.SynthesisMessage do
  @moduledoc """
  Message used to request a text synthesis, this is a SSML.  

  Path: ssml  
  Content-Type: application/ssml+xml  
  MessageType: text  
  """
  @moduledoc section: :text_to_speech
  defstruct [:payload]

  alias __MODULE__

  @type t() :: %SynthesisMessage{payload: String.t()}

  @doc """
  Creates a new SynthesisMessage with the given SSML payload.
  """
  @spec ssml(String.t()) :: t()
  def ssml(ssml),
    do: %SynthesisMessage{payload: ssml}

  @doc """
  Creates a new SynthesisMessage with the given text, voice, and language.
  """
  @spec text(String.t(), String.t(), String.t()) :: t()
  def text(text, voice, language),
    do: %SynthesisMessage{payload: build_ssml(text, voice, language)}

  defp build_ssml(text, voice, language) do
    """
    <speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="#{language}">
      <voice name="#{voice}">
        #{text}
      </voice>
    </speak>
    """
  end

  defimpl ExAzureSpeech.Common.Protocols.SocketMessage,
    for: SynthesisMessage do
    alias ExAzureSpeech.Common.{Guid, HeaderNames, SocketMessage}
    alias ExAzureSpeech.Common.Messages.MessageType

    def build_message(message, id) do
      %SocketMessage{
        id: Guid.create_no_dash_guid(),
        message_type: MessageType.text(),
        payload: message.payload,
        headers: [
          {HeaderNames.path(), "ssml"},
          {HeaderNames.request_id(), id},
          {HeaderNames.content_type(), "application/ssml+xml"},
          {HeaderNames.request_timestamp(), DateTime.utc_now() |> DateTime.to_iso8601()}
        ]
      }
    end
  end
end
