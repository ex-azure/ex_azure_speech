defmodule ExAzureCognitiveServicesSpeechSdk.Common.Messages.MessageType do
  def text(), do: 0
  def binary(), do: 1

  @type t() :: 0 | 1
end
