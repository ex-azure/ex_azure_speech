defmodule ExAzureSpeech.TextToSpeech.Errors.SpeechSynthError do
  @moduledoc """
  This error fires when the Speech Service fails to recognize a speech input.
  """
  @moduledoc section: :text_to_speech
  use Splode.Error, fields: [:reason], class: :internal

  @type t() :: Splode.Error.t()

  @doc false
  def message(%{reason: reason}) do
    "Failed to synthesize speech: #{reason}"
  end
end
