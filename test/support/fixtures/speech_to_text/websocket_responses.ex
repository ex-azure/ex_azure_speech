defmodule ExAzureSpeech.Support.Fixtures.SpeechToText.WebsocketResponses do
  @moduledoc false

  def turn_start(),
    do:
      """
      X-RequestId:EBC5D6D7B53E42C6B45F612BE83EB1A5
      Path:turn.start
      Content-Type:application/json; charset=utf-8


      {
        "context": {
        "serviceTag": "9431ef96ef4e4f28b1147d0feeb18dfc"
        }
      }
      """
      |> String.replace(~r/\n/, "\r\n")

  def speech_start_detected(),
    do:
      """
      X-RequestId:8D8A8D7F1D3A4C3F9D4C3F8E9D4D3A4C
      Path:speech.startDetected
      Content-Type:application/json; charset=utf-8


      {
        "Offset": 7300000
      }
      """
      |> String.replace(~r/\n/, "\r\n")

  def speech_hypothesis(),
    do:
      """
      X-RequestId:8D8A8D7F1D3A4C3F9D4C3F8E9D4D3A4C
      Path:speech.hypothesis
      Content-Type:application/json; charset=utf-8


      {
      "Id": "f9c914484c27405793913009420dc81b",
      "Text": "by voice is my pass",
      "Offset": 7300000,
      "Duration": 14400000,
      "PrimaryLanguage": {
        "Language": "en-US"
      },
      "Channel": 0
      }
      """
      |> String.replace(~r/\n/, "\r\n")

  def speech_end_detected(),
    do:
      """
      X-RequestId:8D8A8D7F1D3A4C3F9D4C3F8E9D4D3A4C
      Path:speech.endDetected
      Content-Type:application/json; charset=utf-8


      {
        "Offset": 38700000
      }
      """
      |> String.replace(~r/\n/, "\r\n")

  def speech_phrase(),
    do:
      """
      X-RequestId:8D8A8D7F1D3A4C3F9D4C3F8E9D4D3A4C
      Path:speech.phrase
      Content-Type:application/json; charset=utf-8


      {
        "Id": "7c52f1647ea74715ae12ed8483dfd80e",
        "RecognitionStatus": "Success",
        "DisplayText": "My voice is my password verify me.",
        "Offset": 7300000,
        "Duration": 27600000,
        "Channel": 0
      }
      """
      |> String.replace(~r/\n/, "\r\n")

  def invalid_speech_phrase(),
    do:
      """
      X-RequestId:8D8A8D7F1D3A4C3F9D4C3F8E9D4D3A4C
      Path:speech.phrase
      Content-Type:application/json; charset=utf-8


      {
        "Id": "7c52f1647ea74715ae12ed8483dfd80e"
        "RecognitionStatus": "Success",
      }
      """
      |> String.replace(~r/\n/, "\r\n")

  def turn_end(),
    do:
      """
      X-RequestId:8D8A8D7F1D3A4C3F9D4C3F8E9D4D3A4C
      Path:turn.end
      Content-Type:application/json; charset=utf-8


      {}
      """
      |> String.replace(~r/\n/, "\r\n")
end
