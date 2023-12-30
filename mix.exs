defmodule Akismet.MixProject do
  use Mix.Project

  def project do
    [
      app: :akismet,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Akismet",
      description: "Easily check comments with Akismet from Elixir.",
      source_url: "https://github.com/PerpetualCreativity/akismet",
      package: [
        name: "akismet",
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/PerpetualCreativity/akismet"},
      ],
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
      {:httpoison, "~> 2.2"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.25", only: :dev},
    ]
  end
end
