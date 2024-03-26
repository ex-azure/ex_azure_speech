defmodule ExAzureCognitiveServicesSpeechSdk.PronunciationAssessment.Dimension do
  @type t() :: :basic | :comprehensive

  def basic(), do: :basic
  def comprehensive(), do: :comprehensive

  def to_string(:basic), do: "Basic"
  def to_string(:comprehensive), do: "Comprehensive"
end
