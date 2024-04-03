defmodule ExAzureSpeech.Common.Errors.InvalidMessage do
  @moduledoc """
  Define errors when serializing client to server messages.
  """
  @moduledoc section: :common
  use Splode.Error, fields: [:name, :errors], class: :invalid

  @type t() :: Splode.Error.t()

  def message(%{name: name, errors: errors}) do
    "Invalid message: #{name} - #{inspect(errors)}"
  end
end
