# ExAzureSpeech

[![Hex](https://img.shields.io/hexpm/v/ex_azure_speech?style=flat-square)](https://hex.pm/packages/ex_azure_speech)
[![.github/workflows/build_and_test.yaml](https://github.com/YgorCastor/ex_azure_speech/actions/workflows/build_and_test.yaml/badge.svg)](https://github.com/YgorCastor/ex_azure_speech/actions/workflows/build_and_test.yaml)

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
File.stream!("test.wav") |> SpeechToText.recognize_once()

{:ok,
  [%ExAzureSpeech.SpeechToText.Responses.SpeechPhrase{
    channel: 0,
    display_text: "My voice is my passport verify me.",
    duration: 27600000,
    id: "ada609c747614c118ac9df6545118646",
    n_best: nil,
    offset: 7300000,
    primary_language: nil,
    recognition_status: "Success",
    speaker_id: nil
  }]}
```

### Text-to-Speech

To configure the text-to-speech module, you need to add the following module to your supervision tree.
```elixir
children = [
  ExAzureSpeech.TextToSpeech.Synthesizer
]

Supervisor.start_link(children, strategy: :one_for_one)
```

#### Example

```elixir
{:ok, stream} = TextToSpeech.speak_text("Hello. World.", "en-US-AriaNeural", "en-US")

{:ok, #Function<52.48886818/2 in Stream.resource/3>}

stream
|> Stream.into(File.stream!("hello_world.wav"))
|> Stream.run()
```

## Readiness

This library is still in continuous development, so contracts and APIs may change considerably. Please, use it at your own risk.

## Roadmap

- ~~Text-to-Speech~~
- Translation
- Speech Intent
- Avatars

