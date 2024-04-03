defmodule ExAzureSpeech.SpeechToText.Messages.SpeechContextMessage do
  @moduledoc """
  Message used to set the context of the speech to text service, such as if prosody accessment is enabled or not.  

  Path: speech.context  
  Content-Type: application/json  
  MessageType: text  
  """
  @moduledoc section: :speech_to_text
  defstruct [:payload]

  alias __MODULE__

  alias ExAzureSpeech.SpeechToText.{
    Dimension,
    GradingSystem,
    Granularity,
    SpeechContextConfig
  }

  @type t() :: %SpeechContextMessage{payload: map()}

  @spec new(SpeechContextConfig.t()) :: SpeechContextMessage.t()
  def new(speech_assessment: opts),
    do: %SpeechContextMessage{
      payload: %{
        "phraseDetection" => %{
          "enrichment" => %{
            "pronunciationAssessment" => %{
              "referenceText" => opts[:reference_text],
              "gradingSystem" => GradingSystem.to_string(opts[:grading_system]),
              "granularity" => Granularity.to_string(opts[:granularity]),
              "dimension" => Dimension.to_string(opts[:dimension]),
              "enableProsodyAssessment" => opts[:enable_prosody_assessment],
              "enableMiscue" => opts[:enable_miscue]
            }
          }
        },
        "phraseOutput" => %{
          "detailed" => %{
            "options" => [
              "WordTimings",
              "PronunciationAssessment",
              "SNR"
            ]
          },
          "format" => "Detailed"
        }
      }
    }

  def new(_), do: %SpeechContextMessage{payload: %{}}

  defimpl ExAzureSpeech.Common.Protocols.SocketMessage,
    for: SpeechContextMessage do
    alias ExAzureSpeech.Common.{Guid, HeaderNames, SocketMessage}
    alias ExAzureSpeech.Common.Messages.MessageType

    def build_message(message, id) do
      %SocketMessage{
        id: Guid.create_no_dash_guid(),
        message_type: MessageType.text(),
        payload: Jason.encode!(message.payload),
        headers: [
          {HeaderNames.path(), "speech.context"},
          {HeaderNames.request_id(), id},
          {HeaderNames.content_type(), "application/json"},
          {HeaderNames.request_timestamp(), DateTime.utc_now() |> DateTime.to_iso8601()}
        ]
      }
    end
  end
end
