defmodule ExAzureCognitiveServicesSpeechSdk.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_azure_cognitive_services_speech_sdk,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:fresh, "~> 0.4"},
      {:jason, "~> 1.4"},
      {:mint, "~> 1.5"},
      {:nimble_options, "~> 1.0"},
      {:splode, "~> 0.2"},
      {:tesla, "~> 1.8"},
      {:elixir_uuid, "~> 1.2"}
    ]
  end
end
