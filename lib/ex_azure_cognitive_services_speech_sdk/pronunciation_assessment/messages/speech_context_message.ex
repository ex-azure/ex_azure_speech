defmodule ExAzureCognitiveServicesSpeechSdk.PronunciationAssessment.Messages.SpeechContextMessage do
  alias __MODULE__

  alias ExAzureCognitiveServicesSpeechSdk.PronunciationAssessment.{
    Dimension,
    GradingSystem,
    Granularity
  }

  defstruct [:payload]

  @schema NimbleOptions.new!(
            grading_system: [
              type: {:in, [:five_point, :hundred_mark]},
              required: true,
              default: :five_point
            ],
            granularity: [
              type: {:in, [:phoneme, :word]},
              required: true,
              default: :phoneme
            ],
            dimension: [
              type: {:in, [:comprehensive, :basic]},
              required: true,
              default: :comprehensive
            ],
            enable_prosody_accessment: [
              type: :boolean,
              required: true,
              default: true
            ],
            enable_miscue: [
              type: :boolean,
              required: true,
              default: false
            ]
          )

  @default [
    grading_system: :five_point,
    granularity: :phoneme,
    dimension: :comprehensive,
    enable_prosody_accessment: true,
    enable_miscue: false
  ]

  def new(reference_text, []), do: new(reference_text, @default)

  def new(reference_text, opts) do
    with opts <- Keyword.merge(@default, opts),
         {:ok, opts} <- NimbleOptions.validate(opts, @schema) do
      {:ok, payload(reference_text, opts)}
    end
  end

  defp payload(reference_text, opts),
    do: %SpeechContextMessage{
      payload: %{
        "phraseDetection" => %{
          "enrichment" => %{
            "pronunciationAssessment" => %{
              "referenceText" => reference_text,
              "gradingSystem" => GradingSystem.to_string(opts[:grading_system]),
              "granularity" => Granularity.to_string(opts[:granularity]),
              "dimension" => Dimension.to_string(opts[:dimension]),
              "enableProsodyAccessment" => opts[:enable_prosody_accessment],
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

  defimpl ExAzureCognitiveServicesSpeechSdk.Common.Protocols.SocketMessage,
    for: SpeechContextMessage do
    alias ExAzureCognitiveServicesSpeechSdk.Common.{Guid, HeaderNames, SocketMessage}
    alias ExAzureCognitiveServicesSpeechSdk.Common.Messages.MessageType

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
