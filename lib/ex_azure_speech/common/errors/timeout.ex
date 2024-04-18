defmodule ExAzureSpeech.Common.Errors.Timeout do
  @moduledoc """
  Defines the error type for a timeout.
  """
  @moduledoc section: :common
  use Splode.Error, fields: [:operation, :timeout], class: :internal

  @type t() :: Splode.Error.t()

  @doc false
  def message(%{operation: operation, timeout: timeout}) do
    "The operation #{inspect(operation)} timed out after #{inspect(timeout)} milliseconds."
  end
end
