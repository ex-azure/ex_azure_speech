# ExAzureSpeech

The non-official Elixir implementation for Azure Cognitive Services Speech SDK. This project aims to provide all the functionalities described in the [official speech sdk](https://learn.microsoft.com/en-gb/azure/ai-services/speech-service/) for Elixir Projects.

## Getting Started

To use the Elixir Speech SDK you first need to add the dependency in your `mix.exs` file.

```elixir
def deps do
  [
    {:ex_azure_speech, "~> 0.1.0"}
  ]
end
```

Optionally, you can add the following configuration to your `config.exs` file, to globally configure all the SDK basic settings.
```elixir
config :ex_azure_speech,
  region: "westeurope",
  language: "en-US",
  auth_key: "YOUR_AZURE_SUBSCRIPTION_KEY"
```

## Implemented Modules

### Speech-to-Text with Pronunciation Assessment

To configure the speech-to-text module, you need to add the following module to your supervision tree.

```elixir
children = [
  ExAzureSpeech.SpeechToText.Recognizer
]

Supervisor.start_link(children, strategy: :one_for_one)
```

#### Example
```elixir
Recognizer.recognize_once(:file, "priv/samples/myVoiceIsMyPassportVerifyMe01.wav")
{:ok,
  %ExAzureSpeech.SpeechToText.Responses.SpeechPhrase{
    channel: 0,
    display_text: "My voice is my passport verify me.",
    duration: 27600000,
    id: "ada609c747614c118ac9df6545118646",
    n_best: nil,
    offset: 7300000,
    primary_language: nil,
    recognition_status: "Success",
    speaker_id: nil
  }}
```

## Roadmap

- Text-to-Speech
- Translation
- Speech Intent
- Avatars



