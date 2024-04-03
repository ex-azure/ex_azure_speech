defmodule ExAzureSpeech.Auth.Config do
  @moduledoc """
  Configuration required to authenticate with the Azure Cognitive Services Speech Pronunciation Assessment API.
  """
  @moduledoc section: :auth
  @schema NimbleOptions.new!(
            auth_key: [
              type: :string,
              required: true,
              doc: "The API Key for the Azure Cognitive Services"
            ],
            region: [
              type: :string,
              required: true,
              doc: "The region where the Azure Cognitive Services is hosted, eg: 'westus'"
            ]
          )

  alias __MODULE__

  @typedoc """
  #{NimbleOptions.docs(@schema)}  
  ## Example Configuration  

      [
        region: "westus",
        auth_key: "your_subscription_key",
      ]

  Default global values can be set in the application configuration.  

      config :ex_azure_speech,
        region: "westus",
        auth_key: "your_subscription_key"
  """
  @type t() :: [unquote(NimbleOptions.option_typespec(@schema))]

  @doc """
  Returns a validated basic configuration for the Azure Cognitive Services Speech Pronunciation Accessment.  
  """
  @spec new(Keyword.t()) :: {:ok, t()} | {:error, NimbleOptions.ValidationError.t()}
  def new(config),
    do:
      config
      |> NimbleOptions.validate(@schema)

  @doc """
  Returns the URI for the Azure Cognitive Services Auth API.
  """
  @spec get_uri(Config.t()) :: String.t()
  def get_uri(config), do: "https://#{config[:region]}.api.cognitive.microsoft.com"
end
