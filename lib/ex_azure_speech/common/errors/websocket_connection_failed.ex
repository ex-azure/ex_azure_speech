defmodule ExAzureSpeech.Common.Errors.WebsocketConnectionFailed do
  @moduledoc """
  Defines the error type for a failed websocket connection.
  """
  @moduledoc section: :common
  use Splode.Error, class: :internal

  @type t() :: Splode.Error.t()

  @doc false
  def message(_) do
    "Failed to establish a connection to the websocket server."
  end
end
