defmodule ExAzureSpeech.SpeechToText.Errors.FailedToSendMessage do
  @moduledoc """
  Error that fires up when the internal process message fails to be dispatched.
  """
  @moduledoc section: :speech_to_text
  use Splode.Error, fields: [:name], class: :internal

  @type t() :: Splode.Error.t()

  def message(%{name: name}), do: "Failed to internally dispatch the message: #{inspect(name)}."
end
