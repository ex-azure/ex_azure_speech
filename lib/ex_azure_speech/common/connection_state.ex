defmodule ExAzureSpeech.Common.ConnectionState do
  @moduledoc """
  Defines the state of a websocket connection.
  """
  @moduledoc section: :common
  defstruct connection_id: nil,
            state: :disconnected,
            responses: [],
            context: nil,
            command_queue: :queue.new(),
            audio_stream: nil,
            current_stage: nil,
            last_received_message_timestamp: nil,
            telemetry: []

  alias __MODULE__

  alias ExAzureSpeech.Common.Guid
  alias ExAzureSpeech.Common.ReplayableAudioStream

  @typedoc """
  All possible states for a connection.
  """
  @type state() :: :connecting | :connected | :disconnecting | :disconnected

  @typedoc """
  connection_id: Non-Dashered GUID for the connection.  
  state: The current state of the connection.  
  responses: List of responses.  
  command_queue: Queue of commands that will be executed in the event_loop.--
  context: The context data of the connection.  
  audio_stream: A ReplayableAudioStream to read audio data.  
  current_stage: The current stage of the websocket.  
  last_received_message_timestamp: The timestamp of the last received message from the server.  
  telemetry: List of telemetry data.  
  """
  @type t() :: %ConnectionState{
          connection_id: Guid.t() | nil,
          state: state(),
          responses: list({:error, term()} | {atom(), term()}),
          command_queue: :queue.queue(),
          context: nil | map(),
          audio_stream: nil | ReplayableAudioStream.t(),
          current_stage: nil | atom(),
          last_received_message_timestamp: nil | DateTime.t(),
          telemetry: list({String.t(), String.t()})
        }
end
