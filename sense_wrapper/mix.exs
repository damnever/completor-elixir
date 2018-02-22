defmodule SenseWrapper.MixProject do
  use Mix.Project

  def project do
    [
      app: :sense_wrapper,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # escript: [main_module: SenseWrapper.CLI],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {SenseWrapper.App, []},
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 3.1"},
      {:elixir_sense , git: "git@github.com:msaraiva/elixir_sense.git", ref: "e8e524fc8220a67147881da84149f8560df9bb7f"},
    ]
  end
end
