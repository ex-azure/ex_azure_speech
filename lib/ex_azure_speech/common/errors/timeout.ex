defmodule ExAzureSpeech.Common.Errors.Timeout do
  @moduledoc """
  Defines a timeout error.
  """
  @moduledoc section: :common
  use Splode.Error, fields: [:timeout], class: :internal

  @type t() :: Splode.Error.t()

  def message(timeout) do
    "The operation timed out after #{timeout} milliseconds."
  end
end
