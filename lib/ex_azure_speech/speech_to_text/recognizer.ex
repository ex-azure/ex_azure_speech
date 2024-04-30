defmodule ExAzureSpeech.SpeechToText.Recognizer do
  @moduledoc """
  Speech-to-Text Recognizer module, which provides the functionality to recognize speech from audio input.  

  ## Internals

  The communication with the Speech-to-Text API is done through a WebSocket connection. For safety and isolation purposes,
  each recognition request is handled by a separate WebSocket connection. This is achieved by spawning a new WebSocket process thats supervised by a DynamicSupervisor,
  which will guarantee that the WebSocket connection is properly terminated after the recognition process is done.
  """
  @moduledoc section: :speech_to_text

  alias ExAzureSpeech.SpeechToText.{
    SocketConfig,
    SpeechContextConfig,
    Websocket
  }

  alias ExAzureSpeech.Common.Errors

  @behaviour ExAzureSpeech.SpeechToText

  defmacrop with_connection(socket_opts, context_opts, stream, do: block) do
    quote do
      {:ok, pid} = open_session(unquote(socket_opts), unquote(context_opts), unquote(stream))

      var!(pid) = pid

      unquote(block)
    end
  end

  @impl true
  def recognize_once(stream, opts) do
    socket_opts = Keyword.get(opts, :socket_opts, [])
    speech_context_opts = Keyword.get(opts, :speech_context_opts, [])
    timeout = Keyword.get(opts, :timeout, 15_000)

    with {:ok, socket_opts} <- SocketConfig.new(socket_opts),
         {:ok, speech_context_opts} <- SpeechContextConfig.new(speech_context_opts) do
      with_connection(socket_opts, speech_context_opts, stream) do
        try do
          Task.async(fn ->
            Websocket.process_to_stream(pid, fn _ -> :ok end)
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

  @impl true
  def recognize_continous(stream, opts) do
    socket_opts = Keyword.get(opts, :socket_opts, [])
    speech_context_opts = Keyword.get(opts, :speech_context_opts, [])

    with {:ok, socket_opts} <- SocketConfig.new(socket_opts),
         {:ok, speech_context_opts} <- SpeechContextConfig.new(speech_context_opts) do
      with_connection(socket_opts, speech_context_opts, stream) do
        try do
          Websocket.process_to_stream(pid, &close_session/1)
        rescue
          err ->
            close_session(pid)
            {:error, Errors.Internal.exception(err)}
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
