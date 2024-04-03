defmodule ExAzureSpeech.Common.Errors.InvalidResponse do
  @moduledoc """
  Defines an error type for when the response from the Speech Server.
  """
  @moduledoc section: :common
  use Splode.Error, fields: [:response, :cause], class: :server

  @type t() :: Splode.Error.t()

  def message(%{response: response, cause: cause}) do
    "Invalid response from Speech Server: #{inspect(response)}, cause: #{cause}"
  end
end
