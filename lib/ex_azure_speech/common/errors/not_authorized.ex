defmodule ExAzureSpeech.Common.Errors.NotAuthorized do
  @moduledoc """
  Defines the error type for not being authorized.
  """
  @moduledoc section: :common
  use Splode.ErrorClass, class: :not_authorized
end
