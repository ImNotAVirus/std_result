defmodule StdResult.MixProject do
  use Mix.Project

  @app_name "StdResult"
  @version "0.1.0"
  @url "https://github.com/ImNotAVirus/std_result"

  def project do
    [
      app: :std_result,
      version: @version,
      elixir: "~> 1.12",
      name: @app_name,
      description: "",
      aliases: [docs: &build_docs/1],
      package: package(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
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
      {:stream_data, "~> 0.6", only: :test},
      {:excoveralls, "~> 0.18", only: :test, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["ImNotAVirus"],
      licenses: ["MIT"],
      links: %{"GitHub" => @url},
      files: ~w(lib CHANGELOG.md LICENSE.md mix.exs .formatter.exs README.md)
    ]
  end

  defp build_docs(_) do
    Mix.Task.run("compile")
    ex_doc = Path.join(Mix.path_for(:escripts), "ex_doc")

    unless File.exists?(ex_doc) do
      raise "cannot build docs because escript for ex_doc is not installed"
    end

    args = ["StdResult", @version, Mix.Project.compile_path()]
    opts = ~w[--main StdResult --source-ref v#{@version} --source-url #{@url}]
    System.cmd(ex_doc, args ++ opts)
    Mix.shell().info("Docs built successfully")
  end
end
