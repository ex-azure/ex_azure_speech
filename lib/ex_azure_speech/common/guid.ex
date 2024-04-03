defmodule ExAzureSpeech.Common.Guid do
  @moduledoc """
  Globally unique identifier (GUID) generator.
  """
  @moduledoc section: :common

  @typedoc """
  Non-Dashed GUID, eg: 'C9A2E4D3D2D74C8A8B9E8C5E8A8D2B2F'
  """
  @type t() :: String.t()

  @spec create_no_dash_guid() :: t()
  def create_no_dash_guid(),
    do:
      UUID.uuid4()
      |> String.replace("-", "")
      |> String.upcase()
end
