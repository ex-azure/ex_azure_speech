defmodule ExAzureSpeech.TextToSpeech do
  @moduledoc """
  Azure Text-to-Speech module, which provides the functionality to synthesize text into speech.
  """
  @moduledoc section: :text_to_speech

  alias ExAzureSpeech.Common.Errors
  alias ExAzureSpeech.TextToSpeech.{SocketConfig, SpeechSynthesisConfig, Websocket}

  @behaviour __MODULE__

  @typedoc """
  The options for the Text-to-Speech Synthesizer module.
  """
  @type opts() :: [
          socket_opts: SocketConfig.t() | nil,
          speech_synthesis_opts: SpeechSynthesisConfig.t() | nil,
          timeout: integer() | nil
        ]

  @doc """
  Synthesizes the given SSML into speech.  

  Parameters:  
  - `ssml`: The SSML to synthesize.  
  - `opts`: The options for the synthesis.  
  - `callbacks`: The callbacks for the synthesis. See `ExAzureSpeech.TextToSpeech.Websocket.callbacks()`.  
  """
  @callback speak_ssml(ssml :: String.t(), opts :: opts(), callbacks :: Websocket.callbacks()) ::
              {:ok, [binary() | Errors.Internal.t()]}
              | {:error,
                 Errors.Internal.t()
                 | Errors.InvalidResponse.t()
                 | Errors.Forbidden.t()
                 | NimbleOptions.ValidationError.t()}

  @doc """
  Synthesizes the given text into speech.  

  Parameters:  
  - `text`: The text to synthesize.  
  - `voice`: The voice to use for the synthesis. E.g: en-US-AriaNeural  
  - `language`: The language code for the synthesis. E.g: en-US  
  - `opts`: The options for the synthesis.  
  - `callbacks`: The callbacks for the synthesis. See `ExAzureSpeech.TextToSpeech.Websocket.callbacks()`  
  """
  @callback speak_text(
              text :: String.t(),
              voice :: String.t(),
              language :: String.t(),
              opts :: opts(),
              callbacks :: Websocket.callbacks()
            ) ::
              {:ok, [binary() | Errors.Internal.t()]}
              | {:error,
                 Errors.Internal.t()
                 | Errors.InvalidResponse.t()
                 | Errors.Forbidden.t()
                 | NimbleOptions.ValidationError.t()}

  @impl true
  def speak_ssml(ssml, opts \\ [], callbacks \\ []),
    do: impl().speak_ssml(ssml, opts, callbacks)

  @impl true
  def speak_text(text, voice, language, opts \\ [], callbacks \\ []),
    do: impl().speak_text(text, voice, language, opts, callbacks)

  defp impl(),
    do:
      Application.get_env(
        :ex_azure_speech,
        :synthesizer,
        ExAzureSpeech.TextToSpeech.Synthesizer
      )
end
