defmodule ExAzureSpeech.Common.Errors.Invalid do
  @moduledoc """
  Defines the error type for invalid data.
  """
  @moduledoc section: :common
  use Splode.ErrorClass, class: :invalid
end
