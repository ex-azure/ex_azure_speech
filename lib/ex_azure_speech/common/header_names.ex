defmodule ExAzureSpeech.Common.HeaderNames do
  @moduledoc """
  Common header names used in the Azure Cognitive Services API
  """
  @moduledoc section: :common
  use ExAzureSpeech.Common.KeyValue,
    auth_key: "Ocp-Apim-Subscription-Key",
    authorization: "Authorization",
    sp_id_auth_key: "Apim-Subscription-Id",
    connection_id: "X-ConnectionId",
    content_type: "Content-Type",
    custom_commands_app_id: "X-CommandsAppId",
    path: "Path",
    request_id: "X-RequestId",
    request_stream_id: "X-StreamId",
    request_timestamp: "X-Timestamp"
end
