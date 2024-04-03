defmodule ExAzureSpeech.SpeechToText.Responses.PrimaryLanguage do
  @moduledoc """
  Represents the primary language of the speech.
  """
  @moduledoc section: :speech_to_text
  defstruct [:language, :confidence]

  @type t :: %__MODULE__{
          language: String.t(),
          confidence: String.t()
        }
end
