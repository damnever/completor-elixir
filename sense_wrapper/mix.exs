defmodule SenseWrapper.MixProject do
  use Mix.Project

  def project do
    [
      app: :sense_wrapper,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: [test: "test --no-start"],
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
      {:elixir_sense , git: "https://github.com/msaraiva/elixir_sense.git", ref: "4d63a5e347adab53a8f51680995d1e86391de536"},
    ]
  end
end
