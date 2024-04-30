defmodule ExAzureSpeech.Common.QueryParameterNames do
  @moduledoc """
  Common query parameter names used in the Azure Cognitive Services API
  """
  @moduledoc section: :common
  use ExAzureSpeech.Common.KeyValue,
    custom_voice_deployment_id: "deploymentId"
end
