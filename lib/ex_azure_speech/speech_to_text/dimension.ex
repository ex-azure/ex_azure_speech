defmodule ExAzureSpeech.SpeechToText.Dimension do
  @moduledoc """
  The dimension of the details returned by the speech acessment from the Steep-To-Text service.
  """
  @moduledoc section: :speech_to_text
  @type t() :: :basic | :comprehensive

  @doc false
  def basic(), do: :basic
  @doc false
  def comprehensive(), do: :comprehensive

  @doc false
  def to_string(:basic), do: "Basic"
  def to_string(:comprehensive), do: "Comprehensive"
end
