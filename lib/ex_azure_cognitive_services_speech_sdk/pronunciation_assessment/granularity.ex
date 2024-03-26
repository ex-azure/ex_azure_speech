defmodule ExAzureCognitiveServicesSpeechSdk.PronunciationAssessment.Granularity do
  @type t() :: :phoneme | :word | :sentence

  def phoneme(), do: :phoneme
  def word(), do: :word
  def sentence(), do: :sentence

  def to_string(:phoneme), do: "Phoneme"
  def to_string(:word), do: "Word"
  def to_string(:sentence), do: "Sentence"
end
