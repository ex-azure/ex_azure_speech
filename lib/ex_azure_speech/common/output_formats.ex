defmodule ExAzureSpeech.Common.OutputFormats do
  @moduledoc """
  Module for defining the supported output formats for the Azure Speech service.
  """
  @moduledoc section: :common

  @formats [
    audio_16khz_16bit_32kbps_mono_opus: "audio-16khz-16bit-32kbps-mono-opus",
    audio_24khz_16bit_24kbps_mono_opus: "audio-24khz-16bit-24kbps-mono-opus",
    audio_24khz_16bit_48kbps_mono_opus: "audio-24khz-16bit-48kbps-mono-opus",
    audio_16khz_16kbps_mono_siren: "audio-16khz-16kbps-mono-siren",
    audio_16khz_32kbitrate_mono_mp3: "audio-16khz-32kbitrate-mono-mp3",
    audio_16khz_128kbitrate_mono_mp3: "audio-16khz-128kbitrate-mono-mp3",
    audio_16khz_64kbitrate_mono_mp3: "audio-16khz-64kbitrate-mono-mp3",
    audio_24khz_48kbitrate_mono_mp3: "audio-24khz-48kbitrate-mono-mp3",
    audio_24khz_96kbitrate_mono_mp3: "audio-24khz-96kbitrate-mono-mp3",
    audio_24khz_160kbitrate_mono_mp3: "audio-24khz-160kbitrate-mono-mp3",
    audio_48khz_96kbitrate_mono_mp3: "audio-48khz-96kbitrate-mono-mp3",
    audio_48khz_192kbitrate_mono_mp3: "audio-48khz-192kbitrate-mono-mp3",
    ogg_16khz_16bit_mono_opus: "ogg-16khz-16bit-mono-opus",
    ogg_24khz_16bit_mono_opus: "ogg-24khz-16bit-mono-opus",
    ogg_48khz_16bit_mono_opus: "ogg-48khz-16bit-mono-opus",
    raw_8khz_8bit_mono_alaw: "raw-8khz-8bit-mono-alaw",
    raw_8khz_8bit_mono_mulaw: "raw-8khz-8bit-mono-mulaw",
    raw_8khz_16bit_mono_pcm: "raw-8khz-16bit-mono-pcm",
    raw_16khz_16bit_mono_truesilk: "raw-16khz-16bit-mono-truesilk",
    raw_16khz_16bit_mono_pcm: "raw-16khz-16bit-mono-pcm",
    raw_22050hz_16bit_mono_pcm: "raw-22050hz-16bit-mono-pcm",
    raw_24khz_16bit_mono_pcm: "raw-24khz-16bit-mono-pcm",
    raw_24khz_16bit_mono_truesilk: "raw-24khz-16bit-mono-truesilk",
    raw_44100hz_16bit_mono_pcm: "raw-44100hz-16bit-mono-pcm",
    raw_48khz_16bit_mono_pcm: "raw-48khz-16bit-mono-pcm",
    riff_8khz_8bit_mono_alaw: "riff-8khz-8bit-mono-alaw",
    riff_8khz_8bit_mono_mulaw: "riff-8khz-8bit-mono-mulaw",
    riff_8khz_16bit_mono_pcm: "riff-8khz-16bit-mono-pcm",
    riff_16khz_16kbps_mono_siren: "riff-16khz-16kbps-mono-siren",
    riff_16khz_16bit_mono_pcm: "riff-16khz-16bit-mono-pcm",
    riff_22050hz_16bit_mono_pcm: "riff-22050hz-16bit-mono-pcm",
    riff_24khz_16bit_mono_pcm: "riff-24khz-16bit-mono-pcm",
    riff_44100hz_16bit_mono_pcm: "riff-44100hz-16bit-mono-pcm",
    riff_48khz_16bit_mono_pcm: "riff-48khz-16bit-mono-pcm",
    webm_16khz_16bit_mono_opus: "webm-16khz-16bit-mono-opus",
    webm_24khz_16bit_mono_opus: "webm-24khz-16bit-mono-opus",
    webm_24khz_16bit_24kbps_mono_opus: "webm-24khz-16bit-24kbps-mono-opus"
  ]

  @typedoc """
  Allowed audio output formats
  """
  @type t() :: unquote(@formats |> Keyword.keys() |> Enum.reduce(&{:|, [], [&1, &2]}))

  defmacro formats() do
    Enum.map(unquote(@formats), fn {_function_name, value} ->
      value
    end)
  end

  for {function_name, value} <- @formats do
    @doc false
    @spec unquote(function_name)() :: String.t()
    def unquote(function_name)(), do: unquote(value)
  end
end
