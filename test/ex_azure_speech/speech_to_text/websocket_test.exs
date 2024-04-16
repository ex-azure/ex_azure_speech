defmodule ExAzureSpeech.SpeechToText.WebsocketTest do
  use ExUnit.Case, async: true

  alias ExAzureSpeech.Common.{ConnectionState, ReplayableAudioStream}
  alias ExAzureSpeech.SpeechToText.Websocket

  alias ExAzureSpeech.Support.Fixtures.SpeechToText.WebsocketResponses
  alias ExAzureSpeech.Support.Fixtures.SpeechToText.SocketMessageFixtures

  describe "handle_in/2" do
    test "should handle a turn.start message" do
      assert {:ok, %ConnectionState{current_stage: :turn_start}} =
               Websocket.handle_in({:text, WebsocketResponses.turn_start()}, %ConnectionState{})
    end

    test "should handle a speech.startDetected message" do
      assert {:ok, %ConnectionState{current_stage: :speech_start_detected}} =
               Websocket.handle_in(
                 {:text, WebsocketResponses.speech_start_detected()},
                 %ConnectionState{}
               )
    end

    test "should handle a speech.hypothesis message" do
      assert {:ok, %ConnectionState{current_stage: :speech_hypothesis}} =
               Websocket.handle_in(
                 {:text, WebsocketResponses.speech_hypothesis()},
                 %ConnectionState{}
               )
    end

    test "should handle a speech.phrase message" do
      assert {:ok, %ConnectionState{current_stage: :speech_phrase, responses: [response]}} =
               Websocket.handle_in(
                 {:text, WebsocketResponses.speech_phrase()},
                 %ConnectionState{}
               )

      assert response ==
               {:recognition,
                %ExAzureSpeech.SpeechToText.Responses.SpeechPhrase{
                  channel: 0,
                  display_text: "My voice is my password verify me.",
                  duration: 27_600_000,
                  id: "7c52f1647ea74715ae12ed8483dfd80e",
                  n_best: nil,
                  offset: 7_300_000,
                  primary_language: nil,
                  recognition_status: "Success",
                  speaker_id: nil
                }}
    end

    test "should handle a invalid speech.phrase message" do
      assert {:ok, %ConnectionState{current_stage: :speech_phrase, responses: [response]}} =
               Websocket.handle_in(
                 {:text, WebsocketResponses.invalid_speech_phrase()},
                 %ConnectionState{}
               )

      assert {:error, %ExAzureSpeech.Common.Errors.InvalidResponse{}} =
               response
    end

    test "should handle a speech.endDetected message" do
      assert {:ok,
              %ConnectionState{
                current_stage: :speech_end_detected,
                audio_stream: _
              }} =
               Websocket.handle_in(
                 {:text, WebsocketResponses.speech_end_detected()},
                 %ConnectionState{audio_stream: %ReplayableAudioStream{}}
               )
    end

    test "should handle a turn.end message" do
      assert {:ok, %ConnectionState{current_stage: :turn_end, command_queue: queue}} =
               Websocket.handle_in({:text, WebsocketResponses.turn_end()}, %ConnectionState{})

      assert {[internal: :notify_end], []} = queue
    end
  end

  describe "handle_info/2" do
    test "should handle the event_loop message if the queue is empty" do
      assert {:ok, _} = Websocket.handle_info({:internal, :event_loop}, %ConnectionState{})
    end

    test "should handle a text socket message" do
      queue_with_command = :queue.new()
      queue_with_command = :queue.in(SocketMessageFixtures.text_message(), queue_with_command)

      assert {:reply, {:text, "test_header:test_value\r\n\r\nI'm a text payload"},
              %ExAzureSpeech.Common.ConnectionState{
                connection_id: nil,
                state: :disconnected,
                responses: [],
                command_queue: {[], []},
                current_stage: nil,
                telemetry: []
              }} =
               Websocket.handle_info({:internal, :event_loop}, %ConnectionState{
                 command_queue: queue_with_command
               })
    end

    test "should handle a binary socket message" do
      queue_with_command = :queue.new()
      queue_with_command = :queue.in(SocketMessageFixtures.binary_message(), queue_with_command)

      assert {:reply,
              {:binary,
               <<0, 22, 116, 101, 115, 116, 95, 104, 101, 97, 100, 101, 114, 58, 116, 101, 115,
                 116, 95, 118, 97, 108, 117, 101, 1, 2, 3, 4, 5>>},
              %ExAzureSpeech.Common.ConnectionState{
                connection_id: nil,
                state: :disconnected,
                responses: [],
                command_queue: {[], []},
                current_stage: nil,
                telemetry: []
              }} =
               Websocket.handle_info({:internal, :event_loop}, %ConnectionState{
                 command_queue: queue_with_command
               })
    end
  end
end
