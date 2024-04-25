defmodule ExAzureSpeech.Fixtures.TextToSpeech.WebsocketResponses do
  @moduledoc false

  alias ExAzureSpeech.Common.SocketMessage

  @doc false
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

  def turn_end(),
    do:
      """
      X-RequestId:8D8A8D7F1D3A4C3F9D4C3F8E9D4D3A4C
      Path:turn.end
      Content-Type:application/json; charset=utf-8


      {}
      """
      |> String.replace(~r/\n/, "\r\n")

  @doc false
  def word_boundary(),
    do:
      """
      X-RequestId:8D8A8D7F1D3A4C3F9D4C3F8E9D4D3A4C
      Path:audio.metadata
      Content-Type:application/json; charset=utf-8


      {
        "Metadata": [
          {
            "Type": "WordBoundary",
            "Data": {
              "Offset": 0,
              "Duration": 0,
              "Text": {
                "Text": "by",
                "Length": 2,
                "BoundaryType": "Word"
              }
            }
          }
        ]
      }
      """
      |> String.replace(~r/\n/, "\r\n")

  def sentence_boundary(),
    do:
      """
      X-RequestId:8D8A8D7F1D3A4C3F9D4C3F8E9D4D3A4C
      Path:audio.metadata
      Content-Type:application/json; charset=utf-8


      {
        "Metadata": [
          {
            "Type": "SentenceBoundary",
            "Data": {
              "Offset": 0,
              "Duration": 0,
              "Text": {
                "Text": "by the way",
                "Length": 2,
                "BoundaryType": "Sentence"
              }
            }
          }
        ]
      }
      """
      |> String.replace(~r/\n/, "\r\n")

  def viseme(),
    do:
      """
      X-RequestId:8D8A8D7F1D3A4C3F9D4C3F8E9D4D3A4C
      Path:audio.metadata
      Content-Type:application/json; charset=utf-8


      {
        "Metadata": [
          {
            "Type": "Viseme",
            "Data": {
              "Offset": 0,
              "VisemeId": 0,
              "IsLastAnimation": true
            }
          }
        ]
      }
      """
      |> String.replace(~r/\n/, "\r\n")

  def session_end(),
    do:
      """
      X-RequestId:8D8A8D7F1D3A4C3F9D4C3F8E9D4D3A4C
      Path:audio.metadata
      Content-Type:application/json; charset=utf-8

      {
        "Metadata": [
          {
            "Type": "SessionEnd",
            "Data": {
              "Offset": 0
            }
          }
        ]
      }
      """
      |> String.replace(~r/\n/, "\r\n")

  @doc false
  def unknown_metadata(),
    do:
      """
      X-RequestId:8D8A8D7F1D3A4C3F9D4C3F8E9D4D3A4C
      Path:audio.metadata
      Content-Type:application/json; charset=utf-8


      {
        "Metadata": [
          {
            "Type": "AAAAAA",
            "Data": {}
          }
        ]
      }
      """
      |> String.replace(~r/\n/, "\r\n")

  def audio() do
    %SocketMessage{
      id: "8D8A8D7F1D3A4C3F9D4C3F8E9D4D3A4C",
      message_type: 1,
      headers: [
        {"X-RequestId", "8D8A8D7F1D3A4C3F9D4C3F8E9D4D3A4C"},
        {"Path", "audio"},
        {"Content-Type", "audio/wav"}
      ],
      payload: <<0, 1>>
    }
    |> SocketMessage.serialize()
  end
end
