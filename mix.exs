defmodule Roost.MixProject do
  use Mix.Project

  @version "0.6.0"

  def project do
    [
      app: :roost,
      version: @version,
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "One registration per app: an umbrella app brings its Phoenix pages, menu links " <>
          "and settings to a host web app, and none of it shows when the app is not in the release.",
      package: package(),
      docs: docs(),
      source_url: "https://github.com/kyroco/roost"
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.7", optional: true},
      {:phoenix_live_view, "~> 1.0", optional: true},
      {:plug, "~> 1.15", optional: true},
      {:jason, "~> 1.4", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/kyroco/roost"},
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md .formatter.exs)
    ]
  end

  defp docs do
    [main: "readme", extras: ["README.md", "CHANGELOG.md"], source_ref: "v#{@version}"]
  end
end
