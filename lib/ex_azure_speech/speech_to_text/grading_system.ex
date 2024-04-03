defmodule ExAzureSpeech.SpeechToText.GradingSystem do
  @moduledoc """
  The grading system to be used for pronunciation assessment.
  """
  @moduledoc section: :speech_to_text

  @typedoc """
  hundred_mark: The grading system that uses a 0 to 100-point scale.
  five_point: The grading system that uses a 1 to 5-point scale.
  """
  @type t() :: :hundred_mark | :five_point

  @doc false
  def hundred_mark(), do: :hundred_mark
  @doc false
  def five_point(), do: :five_point

  @doc false
  def to_string(:hundred_mark), do: "HundredMark"
  def to_string(:five_point), do: "FivePoint"
end
