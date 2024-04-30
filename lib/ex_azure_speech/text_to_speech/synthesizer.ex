defmodule ExAzureSpeech.TextToSpeech.Synthesizer do
  @moduledoc """
  Text-to-Speech Synthesizer module, which provides the functionality to synthesize text into speech.  
  """
  @moduledoc section: :text_to_speech

  @behaviour ExAzureSpeech.TextToSpeech

  alias ExAzureSpeech.Common.Errors

  alias ExAzureSpeech.TextToSpeech.{
    SocketConfig,
    SpeechSynthesisConfig,
    Websocket
  }

  alias ExAzureSpeech.TextToSpeech.Messages.SynthesisMessage

  defmacrop with_connection(socket_opts, context_opts, callbacks, do: block) do
    quote do
      {:ok, pid} = open_session(unquote(socket_opts), unquote(context_opts), unquote(callbacks))

      var!(pid) = pid

      unquote(block)
    end
  end

  @impl true
  def speak_text(text, voice, language, opts, callbacks),
    do:
      SynthesisMessage.text(text, voice, language)
      |> speak(opts, callbacks)

  @impl true
  def speak_ssml(ssml, opts, callbacks),
    do: SynthesisMessage.ssml(ssml) |> speak(opts, callbacks)

  defp speak(synthesis_command, opts, callbacks) do
    socket_opts = Keyword.get(opts, :socket_opts, [])
    speech_synthesis_opts = Keyword.get(opts, :speech_synthesis_opts, [])

    with {:ok, socket_opts} <- SocketConfig.new(socket_opts),
         {:ok, speech_synthesis_opts} <- SpeechSynthesisConfig.new(speech_synthesis_opts) do
      with_connection(socket_opts, speech_synthesis_opts, callbacks) do
        try do
          Websocket.synthesize(pid, synthesis_command, &close_session/1)
        rescue
          err ->
            close_session(pid)
            {:error, Errors.Internal.exception(err)}
        end
      end
    end
  end

  defp open_session(socket_opts, context_opts, callbacks),
    do:
      DynamicSupervisor.start_child(
        {:via, PartitionSupervisor, {__MODULE__, self()}},
        {Websocket, {socket_opts, context_opts, callbacks}}
      )

  defp close_session(pid),
    do:
      DynamicSupervisor.terminate_child(
        {:via, PartitionSupervisor, {__MODULE__, self()}},
        pid
      )

  @doc false
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_opts) do
    children = [
      {PartitionSupervisor, child_spec: DynamicSupervisor, name: __MODULE__}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @doc false
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end
end
