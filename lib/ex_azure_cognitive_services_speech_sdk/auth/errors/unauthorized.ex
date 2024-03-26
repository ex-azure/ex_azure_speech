defmodule ExAzureCognitiveServicesSpeechSdk.Auth.Errors.Unauthorized do
  use Splode.Error, class: :not_authorized

  @impl true
  def message(cause) do
    "Unauthorized: #{cause}"
  end
end
