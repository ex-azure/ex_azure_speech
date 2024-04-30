defmodule ExAzureSpeech.SpeechToText do
  @moduledoc """
  Speech-to-Text module, which provides the functionality to recognize speech from audio input.  

  ## Supported Formats  

  Right now the recognition service supports only RIFF WAV (WAVE) audio format. The audio must be mono, with a sample rate of 16 kHz and 16-bit PCM encoding.
  """
  @moduledoc section: :speech_to_text

  alias ExAzureSpeech.Common.Errors
  alias ExAzureSpeech.SpeechToText.{SocketConfig, SpeechContextConfig}
  alias ExAzureSpeech.SpeechToText.Responses.SpeechPhrase

  @behaviour __MODULE__

  @typedoc """
  See the `SocketConfig.t()` and `SpeechContextConfig.t()` module for more information on the available options.
  """
  @type opts() :: [
          socket_opts: SocketConfig.t() | nil,
          speech_context_opts: SpeechContextConfig.t() | nil,
          timeout: integer() | nil
        ]

  @doc """
  Synchronously recognizes speech from the given audio input.
  """
  @callback recognize_once(audio_stream :: Enumerable.t(), recognition_options :: opts()) ::
              {:ok, list(SpeechPhrase.t())}
              | {:error,
                 Errors.Internal.t()
                 | Errors.InvalidResponse.t()
                 | Errors.Forbidden.t()
                 | NimbleOptions.ValidationError.t()
                 | Errors.Timeout.t()}

  @doc """
  Recognizes speech from the given audio input continuously. It imediately returns a stream that can be lazily consumed.
  """
  @callback recognize_continous(
              audio_stream :: Enumerable.t(),
              recognition_options :: opts()
            ) ::
              {:ok, Enumerable.t()}
              | {:error,
                 Errors.Internal.t()
                 | Errors.InvalidResponse.t()
                 | Errors.Forbidden.t()
                 | NimbleOptions.ValidationError.t()}

  @impl true
  def recognize_once(audio_stream, recognition_options \\ []),
    do: impl().recognize_once(audio_stream, recognition_options)

  @impl true
  def recognize_continous(audio_stream, recognition_options \\ []),
    do: impl().recognize_continous(audio_stream, recognition_options)

  defp impl(),
    do:
      Application.get_env(
        :ex_azure_speech,
        :recognizer,
        ExAzureSpeech.SpeechToText.Recognizer
      )
end
