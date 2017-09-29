defmodule ThankYouStars.Mixfile do
  use Mix.Project

  @version "0.1.0"
  @github "https://github.com/matsubara0507/thank-you-stars"

  def project do
    [
      app: :thank_you_stars,
      version: @version,
      elixir: "~> 1.4",
      start_permanent: Mix.env == :prod,
      description: "A tool for starring GitHub repositories.",
      package: package(),
      deps: deps(),
      source_url: @github,
      aliases: aliases(),
      spec_paths: ["test"],
      spec_pattern: "*_spec.exs",
      preferred_cli_env: [espec: :test]
    ]
  end

  def application do
    [
      applications: [:httpoison, :tentacat]
    ]
  end

  defp package do
    [
      maintainers: ["MATSUBARA Nobutada"],
      licenses: ["MIT"],
      links: %{GitHub: @github},
      files: ~w(lib LICENSE.md mix.exs README.md)
    ]
  end

  defp deps do
    [
      {:espec, "~> 1.4.6", only: :test},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:httpoison, "~> 0.13"},
      {:ok, "~> 1.9.1"},
      {:poison, "~> 3.1"},
      {:tentacat, "~> 0.7"}
    ]
  end

  defp aliases do
    [
     "test": ["espec"]
    ]
  end
end
