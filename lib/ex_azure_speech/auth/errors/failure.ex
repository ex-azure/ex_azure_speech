defmodule ExAzureSpeech.Auth.Errors.Failure do
  @moduledoc """
  Represents an unexpected authentication error.
  """
  @moduledoc section: :auth
  use Splode.Error, fields: [:cause], class: :invalid_response

  @type t() :: Splode.Error.t()

  @impl true
  def message(%{cause: cause}) do
    "Unexpected authentication error: #{inspect(cause)}"
  end
end
