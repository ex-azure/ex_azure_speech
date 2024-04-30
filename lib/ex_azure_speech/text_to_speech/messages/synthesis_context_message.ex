defmodule ExAzureSpeech.TextToSpeech.Messages.SynthesisContextMessage do
  @moduledoc """
  Message used to set the context of the text to speech service.  

  Path: synthesis.context  
  Content-Type: application/json  
  MessageType: text  
  """
  @moduledoc section: :text_to_speech

  defstruct [:payload]

  alias __MODULE__

  @type t() :: %SynthesisContextMessage{payload: map()}

  @doc """
  Creates a new SynthesisContextMessage struct.
  """
  def new(opts),
    do:
      %{}
      |> configure_synthesis(opts)
      |> then(fn config -> %SynthesisContextMessage{payload: config} end)

  defp configure_synthesis(current_config, opts),
    do:
      DeepMerge.deep_merge(
        %{
          "synthesis" => %{
            "audio" => %{
              "metadataOptions" => %{
                "bookmarkEnabled" => opts[:audio][:metadata_options][:bookmark_enabled],
                "punctuationBoundaryEnabled" =>
                  opts[:audio][:metadata_options][:punctuation_boundary_enabled],
                "sentenceBoundaryEnabled" =>
                  opts[:audio][:metadata_options][:sentence_boundary_enabled],
                "sessionEndEnabled" => opts[:audio][:metadata_options][:session_end_enabled],
                "visemeEnabled" => opts[:audio][:metadata_options][:viseme_enabled],
                "wordBoundaryEnabled" => opts[:audio][:metadata_options][:word_boundary_enabled]
              },
              "outputFormat" => opts[:audio][:output_format]
            },
            "language" => %{
              "autoDetection" => opts[:language][:auto_detection]
            }
          }
        },
        current_config
      )

  defimpl ExAzureSpeech.Common.Protocols.SocketMessage,
    for: SynthesisContextMessage do
    alias ExAzureSpeech.Common.{Guid, HeaderNames, SocketMessage}
    alias ExAzureSpeech.Common.Messages.MessageType

    def build_message(message, id) do
      %SocketMessage{
        id: Guid.create_no_dash_guid(),
        message_type: MessageType.text(),
        payload: Jason.encode!(message.payload),
        headers: [
          {HeaderNames.path(), "synthesis.context"},
          {HeaderNames.request_id(), id},
          {HeaderNames.content_type(), "application/json"},
          {HeaderNames.request_timestamp(), DateTime.utc_now() |> DateTime.to_iso8601()}
        ]
      }
    end
  end
end
