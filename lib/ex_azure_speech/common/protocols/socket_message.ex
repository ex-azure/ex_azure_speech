defprotocol ExAzureSpeech.Common.Protocols.SocketMessage do
  @moduledoc """
  Defines a protocol for building a message to be sent over a socket.
  """
  @moduledoc section: :common

  alias ExAzureSpeech.Common.{Guid, SocketMessage}

  @doc """
  Builds a message to be sent over a socket.
  """
  @spec build_message(term(), Guid.t()) :: SocketMessage.t()
  def build_message(payload, id)
end
