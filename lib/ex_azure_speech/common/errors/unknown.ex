defmodule ExAzureSpeech.Common.Errors.Unknown do
  @moduledoc """
  Defines the error type for an unknown error.
  """
  @moduledoc section: :common
  use Splode.ErrorClass, class: :unknown
end
