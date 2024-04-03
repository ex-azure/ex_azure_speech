defmodule ExAzureSpeech.Auth.Client do
  @moduledoc """
  Client to authenticate with the Azure Cognitive Services API
  """
  @moduledoc section: :auth
  import Tesla

  alias ExAzureSpeech.Auth.Config, as: AuthConfig
  alias ExAzureSpeech.Auth.Errors.{Failure, Unauthorized}
  alias ExAzureSpeech.Common.HeaderNames

  @doc """
  Issues an authentication token to access the Azure Cognitive Services API.  
  The authentication is a Bearer token that must be passed in the Authorization header of the requests.  
  """
  @spec auth(AuthConfig.t()) :: {:ok, String.t()} | {:error, Failure.t() | Unauthorized.t()}
  def auth(opts) do
    case post(tesla_client(opts), "/sts/v1.0/issueToken", "") do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{status: status}} when status in [401, 403] ->
        {:error, Unauthorized.exception()}

      {:ok, %Tesla.Env{status: 500, body: body}} ->
        {:error, Failure.exception(cause: body)}

      {:error, reason} ->
        {:error, Failure.exception(cause: reason)}
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
