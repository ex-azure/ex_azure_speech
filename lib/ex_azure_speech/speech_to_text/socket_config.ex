defmodule ExAzureSpeech.SpeechToText.SocketConfig do
  @moduledoc """
  Configurations required to establish a WebSocket connection with the Azure Cognitive Speech Service.  
  """
  @moduledoc section: :speech_to_text

  @schema NimbleOptions.new!(
            connection_id: [
              type: :string,
              required: true,
              doc: """
              A unique identifier for the connection. This is used to correlate the recognition results with the requests.
              """
            ],
            auth_key: [
              type: :string,
              required: true,
              doc: """
              The subscription key for the Azure Cognitive Services Speech Service.
              """
            ],
            region: [
              type: :string,
              required: true,
              doc: """
              The region where the Azure Cognitive Services Speech Service is hosted. This is used to determine the base URL for the WebSocket connection.
              """
            ],
            format: [
              type: {:in, [:simple, :detailed]},
              default: :simple,
              doc: """
              The format of the recognition results. `:simple` returns only the recognition result, while `:detailed` returns the recognition result along with the detailed pronunciation assessment.
              """
            ],
            language: [
              type: :string,
              required: true,
              doc: """
              The language of the speech to be recognized. This is used to determine the language model to be used for recognition. E.g., 'en-US', 'fr-FR', etc.
              """
            ],
            recognition_mode: [
              type: {:in, [:interactive, :conversation, :dictation]},
              default: :interactive,
              doc: """
              The recognition mode to be used. `:interactive` is optimized for short phrases, `:conversation` is optimized for conversational speech, and `:dictation` is optimized for long-form speech.
              """
            ]
          )

  @relative_uris [
    interactive: "/speech/recognition/interactive/cognitiveservices/v1",
    conversation: "/speech/recognition/conversation/cognitiveservices/v1",
    dictation: "/speech/recognition/dictation/cognitiveservices/v1",
    universal: "/speech/universal/v"
  ]

  alias __MODULE__

  alias ExAzureSpeech.Common.Guid

  @typedoc """
  #{NimbleOptions.docs(@schema)}  
  ## Example Configuration  

      [
        region: "westus",
        auth_key: "your_subscription_key",
        language: "en-US",
        format: :simple,
        recognition_mode: :interactive
      ]

  Default global values can be set in the application configuration.  

      config :ex_azure_speech,
        region: "westus",
        auth_key: "your_subscription_key",
        language: "en-US",
        pronunciation_assessment: [
          format: :simple,
          recognition_mode: :interactive
        ]
  """
  @type t() :: [unquote(NimbleOptions.option_typespec(@schema))]

  @doc """
  Returns a validated basic configuration for the Azure Cognitive Services Speech Pronunciation Accessment.  
  """
  @spec new(Keyword.t()) :: {:ok, SocketConfig.t()} | {:error, NimbleOptions.ValidationError.t()}
  def new(config),
    do:
      default_config()
      |> Keyword.merge(config)
      |> NimbleOptions.validate(@schema)

  @doc """
  Returns the URI to establish a WebSocket connection with the Azure Cognitive Services Speech Service.
  """
  @spec get_uri(SocketConfig.t()) :: String.t()
  def get_uri(config),
    do:
      "wss://#{config[:region]}.stt.speech.microsoft.com#{get_relative_uri(config)}?format=#{Atom.to_string(config[:format])}&language=#{config[:language]}"

  defp get_relative_uri(config), do: @relative_uris[config[:recognition_mode]]

  defp default_config,
    do:
      [
        connection_id: Guid.create_no_dash_guid(),
        region: Application.get_env(:ex_azure_speech, :region),
        auth_key: Application.get_env(:ex_azure_speech, :auth_key),
        language: Application.get_env(:ex_azure_speech, :language),
        format:
          Application.get_env(:ex_azure_speech, :pronunciation_assessment)[
            :format
          ],
        recognition_mode:
          Application.get_env(:ex_azure_speech, :pronunciation_assessment)[
            :recognition_mode
          ]
      ]
      |> Keyword.filter(fn {_k, v} -> not is_nil(v) end)
end
