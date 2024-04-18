defmodule Pandora.MixProject do
  use Mix.Project

  def project do
    [
      app: :pandora,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :wx, :observer, :runtime_tools],
      mod: {Pandora.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:floki, "~> 0.36.0"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:req, "~> 0.4.0"},
      {:gen_stage, "~> 1.2"},
      {:broadway, "~> 1.0"}
    ]
  end
end
