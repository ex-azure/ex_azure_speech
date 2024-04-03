defmodule ExAzureSpeech.Common.Messages.MessageType do
  @moduledoc """
  Defines the type of message to be sent.
  """
  @moduledoc section: :common

  @doc false
  @spec text() :: 0
  def text(), do: 0

  @doc false
  @spec binary() :: 1
  def binary(), do: 1

  @typedoc """
  0 - Text message  
  1 - Binary message  
  """
  @type t() :: 0 | 1
end
