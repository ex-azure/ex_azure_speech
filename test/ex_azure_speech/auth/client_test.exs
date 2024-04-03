defmodule ExAzureSpeech.Auth.ClientTest do
  use ExUnit.Case, async: true

  import Tesla.Mock

  alias ExAzureSpeech.Auth.Client, as: AuthClient
  alias ExAzureSpeech.Auth.Config, as: AuthConfig

  test "should authenticate successfully" do
    mock(fn %{
              method: :post,
              url: "https://westeurope.api.cognitive.microsoft.com/sts/v1.0/issueToken"
            } ->
      %Tesla.Env{status: 200, body: "valid_token"}
    end)

    {:ok, auth_config} = AuthConfig.new(auth_key: "valid_key", region: "westeurope")

    assert {:ok, "valid_token"} = AuthClient.auth(auth_config)
  end

  test "if the authentication fails, returns a authentication error" do
    mock(fn %{
              method: :post,
              url: "https://westeurope.api.cognitive.microsoft.com/sts/v1.0/issueToken"
            } ->
      %Tesla.Env{status: 403, body: "Curse you, perry the platypus!"}
    end)

    {:ok, auth_config} = AuthConfig.new(auth_key: "valid_key", region: "westeurope")

    assert {:error, %ExAzureSpeech.Auth.Errors.Unauthorized{}} =
             AuthClient.auth(auth_config)
  end

  test "if the server returns an unexpected error, fails with a different failure code" do
    mock(fn %{
              method: :post,
              url: "https://westeurope.api.cognitive.microsoft.com/sts/v1.0/issueToken"
            } ->
      %Tesla.Env{status: 500, body: "Curse you, perry the platypus!"}
    end)

    {:ok, auth_config} = AuthConfig.new(auth_key: "valid_key", region: "westeurope")

    assert {:error, %ExAzureSpeech.Auth.Errors.Failure{}} =
             AuthClient.auth(auth_config)
  end
end
