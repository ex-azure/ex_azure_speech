defmodule ExAzureSpeech.Common.SocketMessageTest do
  use ExUnit.Case, async: true

  alias ExAzureSpeech.Common.SocketMessage

  alias ExAzureSpeech.Support.Fixtures.SpeechToText.{
    SocketMessageFixtures,
    WebsocketResponses
  }

  test "should serialize text messages" do
    text_message = SocketMessageFixtures.text_message()

    assert "test_header:test_value\r\n\r\nI'm a text payload" =
             SocketMessage.serialize(text_message)
  end

  test "should serialize binary messages" do
    binary_message = SocketMessageFixtures.binary_message()

    assert <<0, 22, 116, 101, 115, 116, 95, 104, 101, 97, 100, 101, 114, 58, 116, 101, 115, 116,
             95, 118, 97, 108, 117, 101, 1, 2, 3, 4, 5>> = SocketMessage.serialize(binary_message)
  end

  test "should deserialize text messages" do
    text_message = WebsocketResponses.speech_hypothesis()

    assert %ExAzureSpeech.Common.SocketMessage{
             id: nil,
             payload:
               "\r\n{\r\n\"Id\": \"f9c914484c27405793913009420dc81b\",\r\n\"Text\": \"by voice is my pass\",\r\n\"Offset\": 7300000,\r\n\"Duration\": 14400000,\r\n\"PrimaryLanguage\": {\r\n  \"Language\": \"en-US\"\r\n},\r\n\"Channel\": 0\r\n}\r\n",
             message_type: 0,
             headers: [
               ["X-RequestId", "8D8A8D7F1D3A4C3F9D4C3F8E9D4D3A4C"],
               ["Path", "speech.hypothesis"],
               ["Content-Type", "application/json; charset=utf-8"]
             ]
           } = SocketMessage.deserialize(:text, text_message)
  end
end
