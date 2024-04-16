defmodule ExAzureSpeech.SpeechToText.RecognizerTest do
  use ExUnit.Case, async: false

  import Mock

  alias ExAzureSpeech.SpeechToText.Recognizer
  alias ExAzureSpeech.SpeechToText.Websocket

  describe "recognize_once/2" do
    test "recognizes speech from audio file" do
      with_mocks([
        {DynamicSupervisor, [],
         [
           start_child: fn _, _ -> {:ok, self()} end
         ]},
        {Websocket, [],
         [process_to_stream: fn _, _ -> {:ok, [%{recognition_status: "Success"}]} end]}
      ]) do
        assert {:ok, [%{recognition_status: "Success"}]} =
                 Recognizer.recognize_once("priv/samples/myVoiceIsMyPassportVerifyMe01.wav")

        assert called(DynamicSupervisor.start_child(:_, :_))
        assert called(Websocket.process_to_stream(:_, :_))
      end
    end
  end
end
