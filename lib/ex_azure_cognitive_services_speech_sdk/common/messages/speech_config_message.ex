defmodule ExAzureCognitiveServicesSpeechSdk.Common.Messages.SpeechConfigMessage do
  @derive Jason.Encoder
  defstruct [:context, :recognition]

  alias __MODULE__

  def new() do
    {os_family, _os_name} = :os.type()

    %SpeechConfigMessage{
      context: %{
        system: %{
          name: "SpeechSDK",
          version: "#{Application.spec(:ex_azure_cognitive_services_speech_sdk, :vsn)}",
          build: "Elixir",
          lang: "Elixir"
        },
        os: %{
          name: Atom.to_string(os_family),
          version: inspect(:os.version()),
          platform: "BEAM"
        },
        audio: %{
          source: %{
            bitspersample: 16,
            channelcount: 1,
            connectivity: "Unknown",
            manufacturer: "Speech SDK",
            model: "File",
            samplerate: 16_000,
            type: "File"
          }
        }
      },
      recognition: :interactive
    }
  end

  defimpl ExAzureCognitiveServicesSpeechSdk.Common.Protocols.SocketMessage,
    for: SpeechConfigMessage do
    alias ExAzureCognitiveServicesSpeechSdk.Common.{Guid, HeaderNames, SocketMessage}
    alias ExAzureCognitiveServicesSpeechSdk.Common.Messages.MessageType

    def build_message(payload, id) do
      %SocketMessage{
        id: Guid.create_no_dash_guid(),
        message_type: MessageType.text(),
        payload: Jason.encode!(payload),
        headers: [
          {HeaderNames.path(), "speech.config"},
          {HeaderNames.request_id(), id},
          {HeaderNames.content_type(), "application/json"},
          {HeaderNames.request_timestamp(), DateTime.utc_now() |> DateTime.to_iso8601()}
        ]
      }
    end
  end
end
