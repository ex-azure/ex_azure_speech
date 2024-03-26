defmodule ExAzureCognitiveServicesSpeechSdk.Config do
  @schema NimbleOptions.new!(
            region: [
              type: :string,
              required: true
            ],
            auth_key: [
              type: :string,
              required: true
            ]
          )

  @type t() :: unquote(NimbleOptions.option_typespec(@schema))

  @doc """
  Returns a validated basic configuration for the Azure Cognitive Services Speech SDK.  

  #{NimbleOptions.docs(@schema)}
  """
  @spec new(Keyword.t()) :: {:ok, t()} | {:error, NimbleOptions.ValidationError.t()}
  def new(config),
    do:
      default_config()
      |> Keyword.merge(config)
      |> NimbleOptions.validate(@schema)

  defp default_config,
    do: [
      region: Application.get_env(:ex_azure_cognitive_services_speech_sdk, :region),
      auth_key: Application.get_env(:ex_azure_cognitive_services_speech_sdk, :auth_key)
    ]
end
