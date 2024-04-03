defmodule ExAzureSpeech.Common.Messages.SpeechConfigMessage do
  @moduledoc """
  Message used to inform the Speech service about which SDK is being used and the type of audio it should expect.  

  Path: speech.config  
  Content-Type: application/json  
  MessageType: text  
  """
  @moduledoc section: :common
  @derive Jason.Encoder
  defstruct [:context, :recognition]

  alias __MODULE__

  @typedoc """
  name: The name of the system sdk.  
  version: The version of the system sdk.  
  build: The build of the system sdk.  
  lang: The programming language of the system sdk.  
  """
  @type system() :: %{
          name: String.t(),
          version: String.t(),
          build: String.t(),
          lang: String.t()
        }

  @typedoc """
  name: The name of the os.  
  version: The version of the os.  
  platform: The platform of the os.  
  """
  @type os() :: %{
          name: String.t(),
          version: String.t(),
          platform: String.t()
        }

  @typedoc """
  bitspersample: The number of bits per sample.  
  channelcount: The number of channels.  
  connectivity: The connectivity of the audio source.  
  manufacturer: The manufacturer of the audio source.  
  model: The model of the audio source.  
  samplerate: The sample rate of the audio source.  
  type: The type of the audio source.  
  """
  @type source() :: %{
          bitspersample: non_neg_integer(),
          channelcount: non_neg_integer(),
          connectivity: String.t(),
          manufacturer: String.t(),
          model: String.t(),
          samplerate: non_neg_integer(),
          type: String.t()
        }

  @typedoc """
  source: The audio source configuration.  
  """
  @type audio() :: %{
          source: source()
        }

  @typedoc """
  system: The system information.  
  os: The os information.  
  audio: The audio information.  
  """
  @type context() :: %{
          system: system(),
          os: os(),
          audio: audio()
        }

  @typedoc """
  context: The context of the message.  
  recognition: The type of recognition to be performed.  
  """
  @type t() :: %SpeechConfigMessage{
          context: context(),
          recognition: :interactive | :conversation | :dictation
        }

  @doc """
  Creates a new SpeechConfigMessage.
  """
  @spec new() :: SpeechConfigMessage.t()
  def new() do
    {os_family, _os_name} = :os.type()

    %SpeechConfigMessage{
      context: %{
        system: %{
          name: "SpeechSDK",
          version: "#{Application.spec(:ex_azure_speech, :vsn)}",
          build: "Elixir",
          lang: "Elixir"
        },
        os: %{
          name: Atom.to_string(os_family),
          version: inspect(:os.version()),
          platform: "BEAM"
        },
        audio: %{
          source: %{
            bitspersample: 16,
            channelcount: 1,
            connectivity: "Unknown",
            manufacturer: "Speech SDK",
            model: "File",
            samplerate: 16_000,
            type: "File"
          }
        }
      },
      recognition: :interactive
    }
  end

  defimpl ExAzureSpeech.Common.Protocols.SocketMessage,
    for: SpeechConfigMessage do
    alias ExAzureSpeech.Common.{Guid, HeaderNames, SocketMessage}
    alias ExAzureSpeech.Common.Messages.MessageType

    def build_message(payload, id) do
      %SocketMessage{
        id: Guid.create_no_dash_guid(),
        message_type: MessageType.text(),
        payload: Jason.encode!(payload),
        headers: [
          {HeaderNames.path(), "speech.config"},
          {HeaderNames.request_id(), id},
          {HeaderNames.content_type(), "application/json"},
          {HeaderNames.request_timestamp(), DateTime.utc_now() |> DateTime.to_iso8601()}
        ]
      }
    end
  end
end
