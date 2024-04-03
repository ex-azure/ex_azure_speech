defmodule ExAzureSpeech.SpeechToText.Responses.SpeechPhrase do
  @moduledoc """
  Represents a valid Speech-To-Text API response.
  """
  @moduledoc section: :speech_to_text

  defstruct [
    :id,
    :channel,
    :recognition_status,
    :display_text,
    :duration,
    :offset,
    :primary_language,
    :n_best,
    :speaker_id
  ]

  @type recognition_status() :: String.t()

  # TODO: Add types for the different outputs of n_best
  @type t() :: %__MODULE__{
          id: String.t(),
          recognition_status: recognition_status(),
          display_text: String.t(),
          duration: integer() | nil,
          offset: integer() | nil,
          primary_language: ExAzureSpeech.SpeechToText.Responses.PrimaryLanguage.t() | nil,
          n_best: [ExAzureSpeech.SpeechToText.Responses.Evaluation.t()] | nil,
          speaker_id: String.t() | nil
        }
end
