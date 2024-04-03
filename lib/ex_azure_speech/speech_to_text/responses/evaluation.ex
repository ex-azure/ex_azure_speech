defmodule ExAzureSpeech.SpeechToText.Responses.Evaluation do
  @moduledoc """
  Phrase details from the Speech-To-Text API.
  """
  @moduledoc section: :speech_to_text
  defstruct [
    :confidence,
    :lexical,
    :itn,
    :masked_itn,
    :display,
    :display_text,
    :words,
    :display_words,
    :pronunciation_assessment
  ]

  @type t :: %__MODULE__{
          confidence: number() | nil,
          lexical: String.t(),
          itn: String.t(),
          masked_itn: String.t(),
          display: String.t() | nil,
          display_text: String.t() | nil,
          words: [ExAzureSpeech.SpeechToText.Responses.Word.t()],
          display_words: [ExAzureSpeech.SpeechToText.Responses.Word.t()],
          pronunciation_assessment:
            ExAzureSpeech.SpeechToText.Responses.PronunciationAssessment.t() | nil
        }
end
