defmodule ExAzureCognitiveServicesSpeechSdk.Auth.Config do
  @schema NimbleOptions.new!(
            auth_key: [
              type: :string,
              required: true
            ],
            region: [
              type: :string,
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
      config
      |> NimbleOptions.validate(@schema)

  def get_uri(config), do: "https://#{config[:region]}.api.cognitive.microsoft.com"
end
