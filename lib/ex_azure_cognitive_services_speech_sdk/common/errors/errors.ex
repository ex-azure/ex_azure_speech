defmodule ExAzureCognitiveServicesSpeechSdk.Common.Errors do
  use Splode,
    error_classes: [
      invalid: ExAzureCognitiveServicesSpeechSdk.Common.Errors.Invalid,
      not_authorized: ExAzureCognitiveServicesSpeechSdk.Common.Errors.NotAuthorized
    ],
    unknown_error: ExAzureCognitiveServicesSpeechSdk.Common.Errors.Unknown
end
