defmodule ThankYouStars.Mixfile do
  use Mix.Project

  @version "0.1.0"
  @github "https://github.com/matsubara0507/thank-you-stars"

  def project do
    [
      app: :thank_you_stars,
      version: @version,
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
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
      applications: [:httpoison]
    ]
  end

  defp package do
    [
      maintainers: ["MATSUBARA Nobutada"],
      licenses: ["MIT"],
      links: %{GitHub: @github},
      files: ~w(lib LICENSE mix.exs README.md)
    ]
  end

  defp deps do
    [
      {:espec, "~> 1.7.0", only: :test},
      {:ex_doc, "~> 0.21.2", only: :dev, runtime: false},
      {:httpoison, "~> 1.6.2"}
    ]
  end

  defp aliases do
    [
      test: ["espec"]
    ]
  end
end
