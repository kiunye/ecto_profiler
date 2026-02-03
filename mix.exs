defmodule EctoProfiler.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_profiler,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      optional_apps: optional_apps()
    ]
  end

  defp optional_apps do
    # Phoenix and LiveView only loaded when present in the host application
    [:phoenix, :phoenix_live_view]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {EctoProfiler.Application, []}
    ]
  end

  defp deps do
    [
      {:ecto, "~> 3.10"},
      {:plug, "~> 1.14"},
      {:telemetry, "~> 1.0"},
      {:phoenix, "~> 1.7", optional: true},
      {:phoenix_live_view, "~> 0.20", optional: true},
      # Code quality and security (dev only)
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:sobelow, "~> 0.12", only: :dev, runtime: false}
    ]
  end
end
