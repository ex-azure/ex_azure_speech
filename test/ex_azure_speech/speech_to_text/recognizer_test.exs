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
           start_child: fn _, _ -> {:ok, self()} end,
           terminate_child: fn _, _ -> :ok end
         ]},
        {Websocket, [],
         [process_to_stream: fn _, _ -> {:ok, [%{recognition_status: "Success"}]} end]}
      ]) do
        assert {:ok, [%{recognition_status: "Success"}]} =
                 Recognizer.recognize_once(<<0, 1>>)

        assert called(DynamicSupervisor.start_child(:_, :_))
        assert called(Websocket.process_to_stream(:_, :_))
        assert called(DynamicSupervisor.terminate_child(:_, :_))
      end
    end

    test "in case of timeout, we should also terminate the child" do
      with_mocks([
        {DynamicSupervisor, [],
         [
           start_child: fn _, _ -> {:ok, self()} end,
           terminate_child: fn _, _ -> :ok end
         ]},
        {Websocket, [],
         [
           process_to_stream: fn _, _ ->
             :timer.sleep(1000)
             {:ok, %{}}
           end
         ]}
      ]) do
        assert {:error, %ExAzureSpeech.Common.Errors.Timeout{}} =
                 Recognizer.recognize_once(<<0, 1>>, timeout: 1)

        assert called(DynamicSupervisor.start_child(:_, :_))
        assert called(DynamicSupervisor.terminate_child(:_, :_))
      end
    end
  end
end
