defmodule ExAzureSpeech.TextToSpeech.Synthesizer do
  @moduledoc """
  Text-to-Speech Synthesizer module, which provides the functionality to synthesize text into speech.  
  """
  @moduledoc section: :text_to_speech

  alias ExAzureSpeech.Common.Errors

  alias ExAzureSpeech.TextToSpeech.{
    SocketConfig,
    SpeechSynthesisConfig,
    Websocket
  }

  alias ExAzureSpeech.TextToSpeech.Messages.SynthesisMessage

  @typedoc """
  The options for the Text-to-Speech Synthesizer module.
  """
  @type opts() :: [
          socket_opts: SocketConfig.t() | nil,
          speech_synthesis_opts: SpeechSynthesisConfig.t() | nil,
          timeout: integer() | nil
        ]

  defmacrop with_connection(socket_opts, context_opts, callbacks, do: block) do
    quote do
      {:ok, pid} = open_session(unquote(socket_opts), unquote(context_opts), unquote(callbacks))

      var!(pid) = pid

      unquote(block)
    end
  end

  @doc """
  Synthesizes the given text into speech.--

  Parameters:--
  - `text`: The text to synthesize.--
  - `voice`: The voice to use for the synthesis. E.g: en-US-AriaNeural --
  - `language`: The language code for the synthesis. E.g: en-US --
  - `opts`: The options for the synthesis. --
  - `callbacks`: The callbacks for the synthesis. See `ExAzureSpeech.TextToSpeech.Websocket.callbacks()`--
  """
  @spec speak_text(
          String.t(),
          String.t(),
          String.t(),
          opts :: opts(),
          callbacks :: Websocket.callbacks()
        ) ::
          {:ok, [binary()]}
          | {:error,
             Errors.Internal.t()
             | Errors.InvalidResponse.t()
             | Errors.Forbidden.t()
             | NimbleOptions.ValidationError.t()}
  def speak_text(text, voice, language, opts \\ [], callbacks \\ []),
    do:
      SynthesisMessage.text(text, voice, language)
      |> speak(opts, callbacks)

  @doc """
  Synthesizes the given SSML into speech.--

  Parameters:--
  - `ssml`: The SSML to synthesize.--
  - `opts`: The options for the synthesis.--
  - `callbacks`: The callbacks for the synthesis. See `ExAzureSpeech.TextToSpeech.Websocket.callbacks()`.--
  """
  @spec speak_ssml(
          String.t(),
          opts :: opts(),
          callbacks :: Websocket.callbacks()
        ) ::
          {:ok, [binary()]}
          | {:error,
             Errors.Internal.t()
             | Errors.InvalidResponse.t()
             | Errors.Forbidden.t()
             | NimbleOptions.ValidationError.t()}
  def speak_ssml(ssml, opts \\ [], callbacks \\ []),
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
