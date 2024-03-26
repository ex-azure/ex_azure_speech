defmodule ExAzureCognitiveServicesSpeechSdk.Auth.Errors.Failure do
  use Splode.Error, class: :invalid

  @impl true
  def message(cause) do
    "Unexpected authentication error: #{inspect(cause)}"
  end
end
