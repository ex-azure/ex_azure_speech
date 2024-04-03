defmodule ExAzureSpeech.Auth.Errors.Unauthorized do
  @moduledoc """
  Return when the informed API Key is not authorized to access the Azure Cognitive Services API.
  """
  @moduledoc section: :auth
  use Splode.Error, class: :not_authorized

  @type t() :: Splode.Error.t()

  @impl true
  def message(cause) do
    "Unauthorized: #{cause}"
  end
end
