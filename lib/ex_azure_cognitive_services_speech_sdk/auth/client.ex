defmodule ExAzureCognitiveServicesSpeechSdk.Auth.Client do
  import Tesla

  alias ExAzureCognitiveServicesSpeechSdk.Auth.Config, as: AuthConfig
  alias ExAzureCognitiveServicesSpeechSdk.Auth.Errors.{Failure, Unauthorized}
  alias ExAzureCognitiveServicesSpeechSdk.Common.HeaderNames

  def auth(opts) do
    case post(tesla_client(opts), "/sts/v1.0/issueToken", "") do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{status: status}} when status in [401, 403] ->
        {:error, Unauthorized.exception()}

      {:error, reason} ->
        {:error, Failure.exception(reason)}
    end
  end

  defp tesla_client(opts),
    do:
      client([
        {Tesla.Middleware.BaseUrl, AuthConfig.get_uri(opts)},
        {Tesla.Middleware.Headers, [{HeaderNames.auth_key(), opts[:auth_key]}]},
        Tesla.Middleware.JSON
      ])
end
