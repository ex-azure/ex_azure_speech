defmodule ExAzureSpeech.TextToSpeech.SynthesizerTest do
  use ExUnit.Case, async: false

  import Mock

  alias ExAzureSpeech.TextToSpeech.Messages.SynthesisMessage
  alias ExAzureSpeech.TextToSpeech.{Synthesizer, Websocket}

  test "synthesizes from text" do
    with_mocks([
      {DynamicSupervisor, [],
       [
         start_child: fn _, _ -> {:ok, self()} end
       ]},
      {Websocket, [], [synthesize: fn _, _, _ -> {:ok, [<<0, 1>>]} end]}
    ]) do
      assert {:ok, [<<0, 1>>]} =
               Synthesizer.speak_text("Hello, world!", "en-US-AriaNeural", "en-US")

      assert called(DynamicSupervisor.start_child(:_, :_))
      assert called(Websocket.synthesize(:_, %SynthesisMessage{payload: expected_ssml()}, :_))
    end
  end

  test "synthesizes from ssml" do
    with_mocks([
      {DynamicSupervisor, [],
       [
         start_child: fn _, _ -> {:ok, self()} end
       ]},
      {Websocket, [], [synthesize: fn _, _, _ -> {:ok, [<<0, 1>>]} end]}
    ]) do
      assert {:ok, [<<0, 1>>]} =
               Synthesizer.speak_ssml("should_be_ssml")

      assert called(DynamicSupervisor.start_child(:_, :_))
      assert called(Websocket.synthesize(:_, %SynthesisMessage{payload: "should_be_ssml"}, :_))
    end
  end

  defp expected_ssml do
    """
    <speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="en-US">
      <voice name="en-US-AriaNeural">
        Hello, world!
      </voice>
    </speak>
    """
  end
end
