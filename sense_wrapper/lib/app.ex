defmodule SenseWrapper.App do
  use Application
  use Supervisor
  alias ElixirSense.Server.ContextLoader

  def start(_type, _args) do
    children = [
      {ContextLoader, ["dev"]},
    ]
    opts = [strategy: :one_for_one, name: SenseWrapper.Supervisor]
    Supervisor.start_link(children, opts)

    run()
  end

  defp run() do
    readline()
    |> String.trim
    |> SenseWrapper.process
    |> IO.puts

    run()
  end

  defp readline() do
    case IO.read(:line) do
      :eof -> System.halt(0)
      {:error, reason} -> System.halt(reason)
      data -> data
    end
  end

end
