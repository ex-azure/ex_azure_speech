defmodule ExAzureSpeech.TextToSpeech.Integration.SynthesizerTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias ExAzureSpeech.Fixtures.TextToSpeech.SSML
  alias ExAzureSpeech.TextToSpeech.Synthesizer

  setup_all do
    children = [
      Synthesizer
    ]

    Supervisor.start_link(children, strategy: :one_for_one)

    Application.put_env(:tesla, :adapter, Tesla.Adapter.Httpc)

    %{}
  end

  describe "speak_text/5" do
    test "should synthesize a plain text" do
      text = "Hello, world!"
      voice = "en-US-AriaNeural"
      language = "en-US"

      {:ok, stream} = Synthesizer.speak_text(text, voice, language)
      # Returns 24 chunks of audio data
      assert 24 == Enum.to_list(stream) |> Enum.count()
    end
  end

  describe "speak_ssml/3" do
    test "should synthesize from a SSML" do
      ssml = SSML.sample()
      {:ok, stream} = Synthesizer.speak_ssml(ssml)
      # Returns 81 chunks of audio data
      assert 81 == Enum.to_list(stream) |> Enum.count()
    end

    test "should the ssml be invalid, an error should be in the stream" do
      ssml = SSML.invalid_sample()
      {:ok, stream} = Synthesizer.speak_ssml(ssml)

      assert [
               %ExAzureSpeech.TextToSpeech.Errors.SpeechSynthError{
                 reason:
                   "Starting September 1st, 2021 standard voices will no longer be supported for new users. Please use n",
                 class: :internal
               }
             ] = Enum.to_list(stream)
    end

    test "should trigger the callbacks" do
      ssml = SSML.sample()
      pid = self()

      {:ok, stream} =
        Synthesizer.speak_ssml(
          ssml,
          [
            speech_synthesis_opts: [
              audio: [
                metadata_options: [
                  bookmark_enabled: false,
                  punctuation_boundary_enabled: true,
                  sentence_boundary_enabled: true,
                  word_boundary_enabled: true,
                  session_end_enabled: true,
                  viseme_enabled: true
                ],
                output_format: "riff-24khz-16bit-mono-pcm"
              ],
              language: [
                auto_detection: false
              ]
            ]
          ],
          viseme_callback: fn _viseme -> send(pid, :viseme) end,
          word_boundary_callback: fn _word_boundary -> send(pid, :word_boundary) end,
          sentence_boundary_callback: fn _sentence_boundary ->
            send(pid, :sentence_boundary)
          end,
          session_end_callback: fn _session_end -> send(pid, :session_end) end
        )

      Stream.run(stream)

      assert_receive :viseme
      assert_receive :word_boundary
      assert_receive :sentence_boundary
      assert_receive :session_end
    end
  end
end
