defmodule ExAzureSpeech.TextToSpeech.WebsocketTest do
  use ExUnit.Case, async: true

  import ExAzureSpeech.Fixtures.TextToSpeech.WebsocketResponses

  alias ExAzureSpeech.Common.SocketMessage
  alias ExAzureSpeech.Common.ConnectionState
  alias ExAzureSpeech.TextToSpeech.Websocket

  describe "audio.metadata handlers" do
    test "should handle WordBoundary metadata triggering the callback" do
      pid = self()

      assert {:ok, %ConnectionState{current_stage: :audio_metadata}} =
               Websocket.handle_in({:text, word_boundary()}, %ConnectionState{
                 callbacks: [
                   word_boundary_callback: fn _word_boundary ->
                     send(pid, :word_boundary)
                   end
                 ]
               })

      assert_receive :word_boundary
    end

    test "should handle SentenceBoundary metadata triggering the callback" do
      pid = self()

      assert {:ok, %ConnectionState{current_stage: :audio_metadata}} =
               Websocket.handle_in({:text, sentence_boundary()}, %ConnectionState{
                 callbacks: [
                   sentence_boundary_callback: fn _sentence_boundary ->
                     send(pid, :sentence_boundary)
                   end
                 ]
               })

      assert_receive :sentence_boundary
    end

    test "should handle Viseme metadata triggering the callback" do
      pid = self()

      assert {:ok, %ConnectionState{current_stage: :audio_metadata}} =
               Websocket.handle_in({:text, viseme()}, %ConnectionState{
                 callbacks: [
                   viseme_callback: fn _viseme ->
                     send(pid, :viseme)
                   end
                 ]
               })

      assert_receive :viseme
    end

    test "should handle SessionEnd metadata triggering the callback" do
      pid = self()

      assert {:ok, %ConnectionState{current_stage: :audio_metadata}} =
               Websocket.handle_in({:text, session_end()}, %ConnectionState{
                 callbacks: [
                   session_end_callback: fn _session_end ->
                     send(pid, :session_end)
                   end
                 ]
               })

      assert_receive :session_end
    end

    test "should ignore unknown metadata" do
      assert {:ok, %ConnectionState{current_stage: :audio_metadata}} =
               Websocket.handle_in({:text, unknown_metadata()}, %ConnectionState{})
    end
  end

  describe "turn messages" do
    test "should handle a turn.start message" do
      assert {:ok, %ConnectionState{current_stage: :turn_start}} =
               Websocket.handle_in({:text, turn_start()}, %ConnectionState{})
    end

    test "should handle a turn.end message" do
      assert {:ok,
              %ConnectionState{
                current_stage: :turn_end,
                command_queue: {[internal: :notify_end], []}
              }} =
               Websocket.handle_in({:text, turn_end()}, %ConnectionState{})
    end
  end

  test "should handle an audio message" do
    assert {:ok, %ConnectionState{current_stage: :audio, responses: [{:synthesis, message}]}} =
             Websocket.handle_in({:binary, audio()}, %ConnectionState{})

    assert %SocketMessage{payload: <<0, 1>>} = message
  end
end
