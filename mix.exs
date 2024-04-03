defmodule ExAzureSpeech.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_azure_speech,
      aliases: aliases(),
      version: "0.0.1",
      elixir: "~> 1.16",
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      deps: deps(),
      dialyzer: [
        plt_core_path: "_plts/core"
      ],
      source_url: "https://github.com/YgorCastor/ex_azure_speech.git",
      homepage_url: "https://github.com/YgorCastor/ex_azure_speech.git",
      docs: [
        main: "readme",
        extras: [
          "CHANGELOG.md": [title: "Changelog"],
          "README.md": [title: "Introduction"],
          LICENSE: [title: "License"]
        ],
        groups_for_modules: [
          Authentication: &(&1[:section] == :auth),
          Common: &(&1[:section] == :common),
          "Speech-To-Text": &(&1[:section] == :speech_to_text)
        ],
        nest_modules_by_prefix: [
          ExAzureSpeech.Common,
          ExAzureSpeech.Authentication,
          ExAzureSpeech.SpeechToText
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:deep_merge, "~> 1.0"},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14", only: :test},
      {:ex_check, "~> 0.14", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:fresh, "~> 0.4"},
      {:jason, "~> 1.4"},
      {:mix_audit, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:mock, "~> 0.3", only: :test, runtime: false},
      {:mint, "~> 1.5"},
      {:nimble_options, "~> 1.0"},
      {:splode, "~> 0.2"},
      {:tesla, "~> 1.8"},
      {:elixir_uuid, "~> 1.2"},
      {:wait_for_it, "~> 2.1"}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      test: ["test --exclude integration"],
      "test.integration": ["test --only integration"]
    ]
  end

  defp description() do
    "The non-official Elixir implementation for Azure Cognitive Services Speech SDK. This project aims to provide all the functionalities described in the official sdk"
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/YgorCastor/ex_azure_speech.git"},
      sponsor: "ycastor.eth"
    ]
  end
end
