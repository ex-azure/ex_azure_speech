defmodule ExAzureSpeech.TextToSpeech.SocketConfig do
  @moduledoc """
  Module for defining the configuration for the Text-to-Speech WebSocket connection.
  """
  @moduledoc section: :text_to_speech

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
            endpoint_id: [
              type: :string,
              required: false,
              doc: """
              Endpoint ID for the custom voice. This is required when using a custom voice model.
              """
            ]
          )

  alias ExAzureSpeech.Common.{Guid, QueryParameterNames}

  alias __MODULE__

  @typedoc """
  #{NimbleOptions.docs(@schema)}  
  ## Example Configuration  

    [
      connection_id: "my-connection-id",
      region: "eastus",
      auth_key: "my-auth-key",
      endpoint_id: "my-endpoint-id"
    ]
  """
  @type t() :: [unquote(NimbleOptions.option_typespec(@schema))]

  @doc """
  Returns a validated configuration for the Text-to-Speech WebSocket connection.
  """
  @spec new(Keyword.t()) :: {:ok, SocketConfig.t()} | {:error, NimbleOptions.ValidationError.t()}
  def new(config),
    do:
      default_config()
      |> Keyword.merge(config)
      |> NimbleOptions.validate(@schema)

  @doc """
  Returns the URI for the Text-to-Speech WebSocket connection.
  """
  @spec get_uri(SocketConfig.t()) :: String.t()
  def get_uri(config),
    do:
      "wss://#{config[:region]}.#{host_prefix(config)}.speech.microsoft.com/cognitiveservices/websocket/v1"
      |> URI.parse()
      |> append_query_params(config)
      |> URI.to_string()

  defp default_config,
    do:
      [
        connection_id: Guid.create_no_dash_guid(),
        region: Application.get_env(:ex_azure_speech, :region),
        auth_key: Application.get_env(:ex_azure_speech, :auth_key)
      ]
      |> Keyword.filter(fn {_k, v} -> not is_nil(v) end)

  defp append_query_params(uri, config), do: uri |> append_custom_voice_deployment_id(config)

  defp append_custom_voice_deployment_id(uri, config) do
    case config[:endpoint_id] do
      nil ->
        uri

      endpoint_id ->
        URI.append_query(
          uri,
          "#{QueryParameterNames.custom_voice_deployment_id()}=#{endpoint_id}"
        )
    end
  end

  defp host_prefix(opts) do
    case opts[:endpoint_id] do
      nil -> "tts"
      _ -> "voice"
    end
  end
end
