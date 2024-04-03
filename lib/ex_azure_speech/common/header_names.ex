defmodule ExAzureSpeech.Common.HeaderNames do
  @moduledoc """
  Common header names used in the Azure Cognitive Services API
  """
  @moduledoc section: :common

  @doc "The API Key for the Azure Cognitive Services"
  @spec auth_key() :: String.t()
  def auth_key, do: "Ocp-Apim-Subscription-Key"

  @doc "Authorizarion Bearer token"
  @spec authorization() :: String.t()
  def authorization, do: "Authorization"

  @spec sp_id_auth_key() :: String.t()
  def sp_id_auth_key, do: "Apim-Subscription-Id"

  @doc "Header that identifies the websocket connection"
  @spec connection_id() :: String.t()
  def connection_id, do: "X-ConnectionId"

  @doc "Header that identifies the content type of the request for the websocket"
  @spec content_type() :: String.t()
  def content_type, do: "Content-Type"

  @spec custom_commands_app_id() :: String.t()
  def custom_commands_app_id, do: "X-CommandsAppId"

  @doc "Path for the internal websocket request dispatcher"
  @spec path() :: String.t()
  def path, do: "Path"

  @doc "Unique identifier for the group of requests in a websocket connection"
  @spec request_id() :: String.t()
  def request_id, do: "X-RequestId"

  @spec request_stream_id() :: String.t()
  def request_stream_id, do: "X-StreamId"

  @spec request_timestamp() :: String.t()
  def request_timestamp, do: "X-Timestamp"
end
