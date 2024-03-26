defmodule ExAzureCognitiveServicesSpeechSdk.Common.Guid do
  @type t() :: String.t()

  def create_no_dash_guid(),
    do:
      UUID.uuid4()
      |> String.replace("-", "")
      |> String.upcase()
end
