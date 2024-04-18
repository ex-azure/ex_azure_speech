defmodule ExAzureSpeech.Common.Errors do
  @moduledoc """
  Defines the error types for the Azure Cognitive Services Speech SDK.
  """
  @moduledoc section: :common
  use Splode,
    error_classes: [
      invalid_request: ExAzureSpeech.Common.Errors.InvalidRequest,
      invalid_response: ExAzureSpeech.Common.Errors.InvalidResponse,
      internal: ExAzureSpeech.Common.Errors.Internal,
      forbidden: ExAzureSpeech.Common.Errors.Forbidden
    ],
    unknown_error: ExAzureSpeech.Common.Errors.Unknown
end

defmodule ExAzureSpeech.Common.Errors.Forbidden do
  @moduledoc """
  Defines the error type for not being authorized.
  """
  @moduledoc section: :common
  use Splode.ErrorClass, class: :forbidden

  @type t() :: Splode.Error.t()
end

defmodule ExAzureSpeech.Common.Errors.Internal do
  @moduledoc """
  Define an error class for internal sdk errors.
  """
  @moduledoc section: :common
  use Splode.ErrorClass, class: :internal

  @type t() :: Splode.Error.t()
end

defmodule ExAzureSpeech.Common.Errors.InvalidRequest do
  @moduledoc """
  Defines the error type for invalid requests to Azure Services.
  """
  @moduledoc section: :common
  use Splode.ErrorClass, class: :invalid_request

  @type t() :: Splode.Error.t()
end

defmodule ExAzureSpeech.Common.Errors.InvalidResponse do
  @moduledoc """
  Defines the error type for invalid responses from Azure Services.
  """
  @moduledoc section: :common
  use Splode.ErrorClass, class: :invalid_response

  @type t() :: Splode.Error.t()
end

defmodule ExAzureSpeech.Common.Errors.Unknown do
  @moduledoc """
  Defines the error type for an unknown error.
  """
  @moduledoc section: :common
  use Splode.ErrorClass, class: :unknown

  @type t() :: Splode.Error.t()
end
