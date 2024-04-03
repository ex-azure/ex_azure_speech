defmodule ExAzureSpeech.Common.Errors do
  @moduledoc """
  Defines the error types for the Azure Cognitive Services Speech SDK.
  """
  @moduledoc section: :common
  use Splode,
    error_classes: [
      invalid: ExAzureSpeech.Common.Errors.Invalid,
      internal: ExAzureSpeech.Common.Errors.Internal,
      not_authorized: ExAzureSpeech.Common.Errors.NotAuthorized,
      server_error: ExAzureSpeech.Common.Errors.Server
    ],
    unknown_error: ExAzureSpeech.Common.Errors.Unknown
end
