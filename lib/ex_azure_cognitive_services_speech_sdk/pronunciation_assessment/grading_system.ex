defmodule ExAzureCognitiveServicesSpeechSdk.PronunciationAssessment.GradingSystem do
  @type t() :: :hundred_mark | :five_point

  def hundred_mark(), do: :hundred_mark
  def five_point(), do: :five_point

  def to_string(:hundred_mark), do: "HundredMark"
  def to_string(:five_point), do: "FivePoint"
end
