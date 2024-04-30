defmodule ExAzureSpeech.Common.QueryParameterNames do
  @moduledoc """
  Common query parameter names used in the Azure Cognitive Services API
  """
  @moduledoc section: :common

  @doc "The query parameter name for the custom voice deployment ID"
  @spec custom_voice_deployment_id() :: String.t()
  def custom_voice_deployment_id, do: "deploymentId"
end
