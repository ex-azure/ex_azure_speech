defmodule ExAzureSpeech.Support.Fixtures.SpeechToText.SocketMessageFixtures do
  @moduledoc false
  alias ExAzureSpeech.Common.SocketMessage

  def text_message() do
    %SocketMessage{
      id: "EBC5D6D7B53E42C6B45F612BE83EB1A5",
      payload: "I'm a text payload",
      message_type: 0,
      headers: [
        {"test_header", "test_value"}
      ]
    }
  end

  def binary_message() do
    %SocketMessage{
      id: "EBC5D6D7B53E42C6B45F612BE83EB1A5",
      payload: <<1, 2, 3, 4, 5>>,
      message_type: 1,
      headers: [
        {"test_header", "test_value"}
      ]
    }
  end
end
