defmodule ExAzureSpeech.SpeechToText.Responses.PronunciationAssessment do
  @moduledoc """
  Overall pronunciation assessment for the Evaluated Speech.
  """
  defstruct [
    :accuracy_score,
    :fluency_score,
    :pronunciation_score,
    :completeness_score
  ]

  @type t :: %__MODULE__{
          accuracy_score: number(),
          fluency_score: number(),
          pronunciation_score: number(),
          completeness_score: number()
        }
end
