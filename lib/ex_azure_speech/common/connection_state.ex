defmodule ExAzureSpeech.Common.ConnectionState do
  @moduledoc """
  Defines the state of a websocket connection.
  """
  @moduledoc section: :common
  defstruct connection_id: nil,
            state: :disconnected,
            response: nil,
            waiting_for_response: [],
            context: nil,
            command_queue: :queue.new(),
            current_stage: nil,
            telemetry: []

  alias __MODULE__

  alias ExAzureSpeech.Common.Guid

  @typedoc """
  All possible states for a connection.
  """
  @type state() :: :connecting | :connected | :disconnecting | :disconnected

  @typedoc """
  connection_id: Non-Dashered GUID for the connection.  
  state: The current state of the connection.  
  response: The response from the server.  
  waiting_for_response: List of PIDs waiting for a response.  
  current_stage: The current stage of the websocket.  
  telemetry: List of telemetry data.  
  """
  @type t() :: %ConnectionState{
          connection_id: Guid.t() | nil,
          state: state(),
          response: nil | {:error, term()} | {atom(), term()},
          waiting_for_response: list(pid()),
          command_queue: :queue.queue(),
          context: nil | map(),
          current_stage: nil | atom(),
          telemetry: list({String.t(), String.t()})
        }
end
