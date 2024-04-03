defmodule ExAzureSpeech.SpeechToText.RecognizerTest do
  use ExUnit.Case, async: false

  import Mock

  alias ExAzureSpeech.SpeechToText.Recognizer
  alias ExAzureSpeech.SpeechToText.Websocket

  describe "recognize_once/3" do
    test "recognizes speech from audio file" do
      with_mocks([
        {DynamicSupervisor, [],
         [
           start_child: fn _, _ -> {:ok, self()} end,
           terminate_child: fn _, _ -> :ok end
         ]},
        {Websocket, [],
         [process_and_wait: fn _, _, _ -> {:ok, %{"RecognitionStatus" => "Success"}} end]}
      ]) do
        assert {:ok, %{"RecognitionStatus" => "Success"}} =
                 Recognizer.recognize_once(
                   :file,
                   "priv/samples/myVoiceIsMyPassportVerifyMe01.wav"
                 )

        assert called(DynamicSupervisor.start_child(:_, :_))
        assert called(Websocket.process_and_wait(:_, :_, :_))
        assert called(DynamicSupervisor.terminate_child(:_, :_))
      end
    end

    test "in case of failures, we should also terminate the child" do
      with_mocks([
        {DynamicSupervisor, [],
         [
           start_child: fn _, _ -> {:ok, self()} end,
           terminate_child: fn _, _ -> :ok end
         ]},
        {Websocket, [], [process_and_wait: fn _, _, _ -> {:error, %{}} end]}
      ]) do
        assert {:error, %{}} =
                 Recognizer.recognize_once(
                   :file,
                   "priv/samples/myVoiceIsMyPassportVerifyMe01.wav"
                 )

        assert called(DynamicSupervisor.start_child(:_, :_))
        assert called(Websocket.process_and_wait(:_, :_, :_))
        assert called(DynamicSupervisor.terminate_child(:_, :_))
      end
    end
  end
end
