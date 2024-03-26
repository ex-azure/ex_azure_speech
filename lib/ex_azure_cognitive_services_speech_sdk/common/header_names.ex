defmodule ExAzureCognitiveServicesSpeechSdk.Common.HeaderNames do
  def auth_key, do: "Ocp-Apim-Subscription-Key"
  def authorization, do: "Authorization"
  def sp_id_auth_key, do: "Apim-Subscription-Id"
  def connection_id, do: "X-ConnectionId"
  def content_type, do: "Content-Type"
  def custom_commands_app_id, do: "X-CommandsAppId"
  def path, do: "Path"
  def request_id, do: "X-RequestId"
  def request_stream_id, do: "X-StreamId"
  def request_timestamp, do: "X-Timestamp"
end
