defmodule SenseWrapper.MixProject do
  use Mix.Project

  def project do
    [
      app: :sense_wrapper,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: SenseWrapper.CLI],
      deps: deps(),
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
      {:poison, "~> 3.1"},
      {:elixir_sense , git: "git@github.com:msaraiva/elixir_sense.git", ref: "feab4e38787babc221f4a85af60336fddf3fc43c"},
    ]
  end
end
