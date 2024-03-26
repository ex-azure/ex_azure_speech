defmodule ExAzureCognitiveServicesSpeechSdk.PronunciationAssessment.SocketConfig do
  @relative_uris [
    interactive: "/speech/recognition/interactive/cognitiveservices/v1",
    conversation: "/speech/recognition/conversation/cognitiveservices/v1",
    dictation: "/speech/recognition/dictation/cognitiveservices/v1",
    universal: "/speech/universal/v"
  ]

  @schema NimbleOptions.new!(
            auth_key: [
              type: :string,
              required: true
            ],
            region: [
              type: :string,
              required: true
            ],
            format: [
              type: {:in, [:simple, :detailed]},
              required: true
            ],
            language: [
              type: :string,
              required: true
            ],
            recognition_mode: [
              type: {:in, [:interactive, :conversation, :dictation]},
              required: true
            ],
            grading_system: [
              type: {:in, [:hundred_mark, :five_point]},
              required: true
            ],
            granularity: [
              type: {:in, [:phoneme, :word, :sentence]},
              required: true
            ],
            dimension: [
              type: {:in, [:basic, :comprehensive]},
              required: true
            ],
            enable_prosody_accessment: [
              type: :boolean,
              required: true
            ],
            enable_miscue: [
              type: :boolean,
              required: true
            ]
          )

  @type t() :: unquote(NimbleOptions.option_typespec(@schema))

  @doc """
  Returns a validated basic configuration for the Azure Cognitive Services Speech Pronunciation Accessment.  

  #{NimbleOptions.docs(@schema)}
  """
  @spec new(Keyword.t()) :: {:ok, t()} | {:error, NimbleOptions.ValidationError.t()}
  def new(config),
    do:
      default_config()
      |> Keyword.merge(config)
      |> NimbleOptions.validate(@schema)

  def get_uri(config),
    do:
      "wss://#{config[:region]}.stt.speech.microsoft.com#{get_relative_uri(config)}?format=#{Atom.to_string(config[:format])}&language=#{config[:language]}"

  defp get_relative_uri(config), do: @relative_uris[config[:recognition_mode]]

  defp default_config,
    do: [
      region: Application.get_env(:ex_azure_cognitive_services_speech_sdk, :region),
      auth_key: Application.get_env(:ex_azure_cognitive_services_speech_sdk, :auth_key),
      format:
        Application.get_env(:ex_azure_cognitive_services_speech_sdk, :pronunciation_accessment)[
          :format
        ],
      language:
        Application.get_env(:ex_azure_cognitive_services_speech_sdk, :pronunciation_accessment)[
          :language
        ],
      recognition_mode:
        Application.get_env(:ex_azure_cognitive_services_speech_sdk, :pronunciation_accessment)[
          :recognition_mode
        ]
    ]
end
