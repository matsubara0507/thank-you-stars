defmodule ThankYouStars.Mixfile do
  use Mix.Project

  def project do
    [
      app: :thank_you_stars,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:floki, :httpoison, :tentacat]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  def deps do
    [
      {:floki, "~> 0.18.0"},
      {:httpoison, "~> 0.13"},
      {:ok, "~> 1.9.1"},
      {:poison, "~> 3.1"},
      {:tentacat, "~> 0.7"}
    ]
  end
end
