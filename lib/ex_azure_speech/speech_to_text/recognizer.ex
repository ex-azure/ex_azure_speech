defmodule ExAzureSpeech.SpeechToText.Recognizer do
  @moduledoc """
  Speech-to-Text Recognizer module, which provides the functionality to recognize speech from audio input.  

  ## Internals

  The communication with the Speech-to-Text API is done through a WebSocket connection. For safety and isolation purposes,
  each recognition request is handled by a separate WebSocket connection. This is achieved by spawning a new WebSocket process thats supervised by a DynamicSupervisor,
  which will guarantee that the WebSocket connection is properly terminated after the recognition process is done.
  """
  @moduledoc section: :speech_to_text
  alias __MODULE__

  alias ExAzureSpeech.SpeechToText.{
    SocketConfig,
    SpeechContextConfig,
    Websocket
  }

  alias ExAzureSpeech.SpeechToText.Responses.SpeechPhrase

  @typedoc """
  See the `SocketConfig.t()` and `SpeechContextConfig.t()` module for more information on the available options.
  """
  @type opts() :: [
          socket_opts: SocketConfig.t() | nil,
          speech_context_opts: SpeechContextConfig.t() | nil
        ]

  defmacrop with_connection(opts, do: block) do
    quote do
      {:ok, pid} =
        DynamicSupervisor.start_child(
          {:via, PartitionSupervisor, {__MODULE__, self()}},
          {Websocket, unquote(opts)}
        )

      var!(pid) = pid

      res = unquote(block)

      DynamicSupervisor.terminate_child(
        {:via, PartitionSupervisor, {__MODULE__, self()}},
        pid
      )

      res
    end
  end

  @doc """
  Synchronously recognizes speech from the given audio input. This function accepts either a file path or a stream as input.


  """
  @spec recognize_once(:file | :stream, String.t() | Enumerable.t(), Recognizer.opts()) ::
          {:ok, SpeechPhrase.t()} | {:error, any}
  def recognize_once(type, audio, opts \\ [])

  def recognize_once(:file, path, opts),
    do: recognize_once(:stream, File.stream!(path, 32_768), opts)

  def recognize_once(:stream, audio, opts) do
    socket_opts = Keyword.get(opts, :socket_opts, [])
    speech_context_opts = Keyword.get(opts, :speech_context_opts, [])

    with {:ok, socket_opts} <- SocketConfig.new(socket_opts),
         {:ok, speech_context_opts} <- SpeechContextConfig.new(speech_context_opts) do
      with_connection(socket_opts) do
        Websocket.process_and_wait(pid, audio, speech_context_opts)
      end
    end
  end

  # TODO: Implement continuous recognition

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_opts) do
    children = [
      {PartitionSupervisor, child_spec: DynamicSupervisor, name: __MODULE__}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
