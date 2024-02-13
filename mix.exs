defmodule StdResult.MixProject do
  use Mix.Project

  def project do
    [
      app: :std_result,
      version: "0.1.0",
      elixir: "~> 1.12",
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: []
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:stream_data, "~> 0.6", only: :test}
    ]
  end
end
