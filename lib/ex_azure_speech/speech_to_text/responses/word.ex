defmodule ExAzureSpeech.SpeechToText.Responses.Word do
  @moduledoc """
  Represents a word in a phrase.
  """
  @moduledoc section: :speech_to_text
  defstruct [
    :word,
    :offset,
    :duration
  ]

  @type t :: %__MODULE__{
          word: String.t(),
          offset: integer(),
          duration: integer()
        }
end
