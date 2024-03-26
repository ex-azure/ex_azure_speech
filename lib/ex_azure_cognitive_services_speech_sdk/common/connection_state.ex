defmodule ExAzureCognitiveServicesSpeechSdk.Common.ConnectionState do
  defstruct [
    :connection_id,
    :state,
    :caller_pid
  ]

  @type state :: :connecting | :connected | :disconnecting | :disconnected
end
