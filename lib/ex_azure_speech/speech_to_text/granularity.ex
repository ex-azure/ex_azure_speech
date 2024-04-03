defmodule ExAzureSpeech.SpeechToText.Granularity do
  @moduledoc """
  Defines the granularity of the recognition results.
  """
  @moduledoc section: :speech_to_text

  @typedoc """
  phoneme: The granularity that returns the phoneme-level recognition results.
  word: The granularity that returns the word-level recognition results.
  sentence: The granularity that returns the sentence-level recognition results.
  """
  @type t() :: :phoneme | :word | :sentence

  @doc false
  def phoneme(), do: :phoneme
  @doc false
  def word(), do: :word
  @doc false
  def sentence(), do: :sentence

  @doc false
  def to_string(:phoneme), do: "Phoneme"
  def to_string(:word), do: "Word"
  def to_string(:sentence), do: "Sentence"
end
