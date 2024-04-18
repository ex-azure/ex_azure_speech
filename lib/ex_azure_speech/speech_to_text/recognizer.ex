defmodule ExAzureSpeech.SpeechToText.Recognizer do
  @moduledoc """
  Speech-to-Text Recognizer module, which provides the functionality to recognize speech from audio input.  

  ## Internals

  The communication with the Speech-to-Text API is done through a WebSocket connection. For safety and isolation purposes,
  each recognition request is handled by a separate WebSocket connection. This is achieved by spawning a new WebSocket process thats supervised by a DynamicSupervisor,
  which will guarantee that the WebSocket connection is properly terminated after the recognition process is done.

  ## Supported Formats

  Right now the recognition service supports only RIFF WAV (WAVE) audio format. The audio must be mono, with a sample rate of 16 kHz and 16-bit PCM encoding.
  """
  @moduledoc section: :speech_to_text
  alias __MODULE__

  alias ExAzureSpeech.SpeechToText.{
    SocketConfig,
    SpeechContextConfig,
    Websocket
  }

  alias ExAzureSpeech.SpeechToText.Responses.SpeechPhrase
  alias ExAzureSpeech.Common.Errors

  @typedoc """
  See the `SocketConfig.t()` and `SpeechContextConfig.t()` module for more information on the available options.
  """
  @type opts() :: [
          socket_opts: SocketConfig.t() | nil,
          speech_context_opts: SpeechContextConfig.t() | nil,
          timeout: integer() | nil
        ]

  defmacrop with_connection(socket_opts, context_opts, stream, do: block) do
    quote do
      {:ok, pid} = open_session(unquote(socket_opts), unquote(context_opts), unquote(stream))

      var!(pid) = pid

      unquote(block)
    end
  end

  @doc """
  Synchronously recognizes speech from the given audio input.
  """
  @spec recognize_once(audio_stream :: Enumerable.t(), recognition_options :: Recognizer.opts()) ::
          {:ok, list(SpeechPhrase.t())}
          | {:error,
             Errors.Internal.t()
             | Errors.InvalidResponse.t()
             | Errors.Forbidden.t()
             | NimbleOptions.ValidationError.t()
             | Errors.Timeout.t()}
  def recognize_once(stream, opts \\ []) do
    socket_opts = Keyword.get(opts, :socket_opts, [])
    speech_context_opts = Keyword.get(opts, :speech_context_opts, [])
    timeout = Keyword.get(opts, :timeout, 15_000)

    with {:ok, socket_opts} <- SocketConfig.new(socket_opts),
         {:ok, speech_context_opts} <- SpeechContextConfig.new(speech_context_opts) do
      with_connection(socket_opts, speech_context_opts, stream) do
        try do
          Task.async(fn ->
            Websocket.process_to_stream(pid)
            |> case do
              {:ok, phrases} -> {:ok, phrases |> Enum.to_list()}
              {:error, reason} -> {:error, reason}
            end
          end)
          |> Task.await(timeout)
        catch
          :exit, _ ->
            {:error, Errors.Timeout.exception(operation: :recognize_once, timeout: timeout)}
        after
          close_session(pid)
        end
      end
    end
  end

  @doc """
  Recognizes speech from the given audio input continuously. It imediately returns a stream that can be lazily consumed.
  """
  @spec recognize_continous(
          audio_stream :: Enumerable.t(),
          recognition_options :: Recognizer.opts()
        ) ::
          {:ok, Enumerable.t()}
          | {:error,
             Errors.Internal.t()
             | Errors.InvalidResponse.t()
             | Errors.Forbidden.t()
             | NimbleOptions.ValidationError.t()}
  def recognize_continous(stream, opts \\ []) do
    socket_opts = Keyword.get(opts, :socket_opts, [])
    speech_context_opts = Keyword.get(opts, :speech_context_opts, [])

    with {:ok, socket_opts} <- SocketConfig.new(socket_opts),
         {:ok, speech_context_opts} <- SpeechContextConfig.new(speech_context_opts) do
      with_connection(socket_opts, speech_context_opts, stream) do
        try do
          Websocket.process_to_stream(pid)
        after
          close_session(pid)
        end
      end
    end
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  defp open_session(socket_opts, context_opts, stream),
    do:
      DynamicSupervisor.start_child(
        {:via, PartitionSupervisor, {__MODULE__, self()}},
        {Websocket, {socket_opts, context_opts, stream}}
      )

  defp close_session(pid),
    do:
      DynamicSupervisor.terminate_child(
        {:via, PartitionSupervisor, {__MODULE__, self()}},
        pid
      )

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_opts) do
    children = [
      {PartitionSupervisor, child_spec: DynamicSupervisor, name: __MODULE__}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
