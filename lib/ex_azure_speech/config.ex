defmodule ExAzureSpeech.Config do
  @moduledoc """
  Configuration module for the Azure Cognitive Services Speech SDK.
  """
  @schema NimbleOptions.new!(
            region: [
              type: :string,
              required: true,
              doc: "The region where the Azure Cognitive Services is hosted, eg: 'westus'"
            ],
            auth_key: [
              type: :string,
              required: true,
              doc: "The Subscription Key for the Azure Cognitive Services"
            ]
          )

  @type t() :: [unquote(NimbleOptions.option_typespec(@schema))]

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
      region: Application.get_env(:ex_azure_speech, :region),
      auth_key: Application.get_env(:ex_azure_speech, :auth_key)
    ]
end
