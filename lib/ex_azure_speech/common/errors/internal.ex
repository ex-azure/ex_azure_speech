defmodule ExAzureSpeech.Common.Errors.Internal do
  @moduledoc """
  Define an error class for internal sdk errors.
  """
  @moduledoc section: :common
  use Splode.ErrorClass, class: :internal
end
