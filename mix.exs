defmodule CsopakWeather.MixProject do
  use Mix.Project

  def project do
    [
      app: :csopak_weather,
      version: "0.1.0",
      elixir: "~> 1.13",
      # include test as path for :test environment, so mocks can be looked up
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {CsopakWeather.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:floki, ">= 0.30.0"},
      {:timex, "~> 3.0"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:httpoison, "~> 1.8"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_), do: ["lib"]
end
