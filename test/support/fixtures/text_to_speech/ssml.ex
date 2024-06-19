defmodule ExAzureSpeech.Fixtures.TextToSpeech.SSML do
  @moduledoc false

  @doc false
  def sample(text \\ "Ohh mijn god") do
    """
    <speak
    	xmlns="http://www.w3.org/2001/10/synthesis"
    	xmlns:mstts="http://www.w3.org/2001/mstts"
    	xmlns:emo="http://www.w3.org/2009/10/emotionml" version="1.0" xml:lang="nl-NL">
    	<voice name="nl-NL-MaartenNeural">#{text}, wat </voice>
    	<voice name="nl-NL-FennaNeural">gebeurt er</voice>
    	<voice name="nl-NL-MaartenNeural">, </voice>
    	<voice name="nl-NL-ColetteNeural">ik denk dat mijn stem verandert.</voice>
    </speak>
    """
  end

  @doc false
  def invalid_voice_sample() do
    """
    <speak
      xmlns="http://www.w3.org/2001/10/synthesis"
      xmlns:mstts="http://www.w3.org/2001/mstts"
      xmlns:emo="http://www.w3.org/2009/10/emotionml" version="1.0" xml:lang="nl-RU">
      <voice name="nl-RU-AAA">Ohh mijn god, wat </voice>
    </speak>
    """
  end

  @doc false
  def invalid_phoneme_sample() do
    """
    <speak
    	xmlns="http://www.w3.org/2001/10/synthesis"
    	xmlns:mstts="http://www.w3.org/2001/mstts"
    	xmlns:emo="http://www.w3.org/2009/10/emotionml" version="1.0" xml:lang="nl-NL">
      <voice name="nl-NL-MaartenNeural"><phoneme alphabet="ipa" ph="(Asdads)">wat</phoneme></voice>
    </speak>
    """
  end
end
