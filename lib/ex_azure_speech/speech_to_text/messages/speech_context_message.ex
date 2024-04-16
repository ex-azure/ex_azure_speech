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

  @doc """
  Create a new SpeechContextMessage with the given configuration options.  
  """
  @spec new(SpeechContextConfig.t()) :: SpeechContextMessage.t()
  def new(opts),
    do:
      %{}
      |> configure_speech_assessment(opts)
      |> configure_phrase_detection(opts)
      |> then(fn config -> %SpeechContextMessage{payload: config} end)

  defp configure_speech_assessment(current_config, opts) do
    if Keyword.has_key?(opts, :speech_assessment) do
      DeepMerge.deep_merge(current_config, %{
        "phraseDetection" => %{
          "enrichment" => %{
            "pronunciationAssessment" => %{
              "referenceText" => opts[:speech_assessment][:reference_text],
              "gradingSystem" =>
                GradingSystem.to_string(opts[:speech_assessment][:grading_system]),
              "granularity" => Granularity.to_string(opts[:speech_assessment][:granularity]),
              "dimension" => Dimension.to_string(opts[:speech_assessment][:dimension]),
              "enableProsodyAssessment" => opts[:speech_assessment][:enable_prosody_assessment],
              "enableMiscue" => opts[:speech_assessment][:enable_miscue]
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
      })
    else
      current_config
    end
  end

  defp configure_phrase_detection(current_config, opts) do
    if Keyword.has_key?(opts, :phrase_detection) do
      recognition_mode =
        Keyword.get(opts[:phrase_detection], :recognition_mode, :interactive)
        |> Atom.to_string()

      DeepMerge.deep_merge(current_config, %{
        "phraseDetection" =>
          Map.put(%{"mode" => recognition_mode}, recognition_mode |> String.upcase(), %{
            "segmentation" => %{
              "mode" => "custom",
              "segmentationSilenceTimeoutMs" =>
                opts[:phrase_detection][:speech_segmentation_silence_ms]
            }
          })
      })
    else
      current_config
    end
  end

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
