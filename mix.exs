defmodule ResultStd.MixProject do
  use Mix.Project

  def project do
    [
      app: :result_std,
      version: "0.1.0",
      elixir: "~> 1.12",
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
      {:stream_data, "~> 0.6", only: :test}
    ]
  end
end
