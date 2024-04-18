defmodule ExAzureSpeech.Common.Errors.FailedToDispatchCommand do
  @moduledoc """
  Defines the error type for a failed dispatch of a command to a websocket client.
  """
  @moduledoc section: :common
  use Splode.Error, fields: [:command, :websocket_pid], class: :internal

  @type t() :: Splode.Error.t()

  @doc false
  def message(%{command: command, websocket_pid: pid}) do
    "Failed to dispatch command: #{inspect(command)} to websocket pid: #{inspect(pid)}."
  end
end
