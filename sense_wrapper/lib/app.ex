defmodule SenseWrapper.App do
  use Application
  use Supervisor
  alias ElixirSense.Server.ContextLoader

  def start(_type, _args) do
    children = [
      {ContextLoader, ["dev"]},
      {Task, fn -> run() end},
    ]
    opts = [strategy: :one_for_one, name: SenseWrapper.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp run() do
    data =
      case IO.read(:line) do
        :eof -> System.halt(0)
        {:error, reason} -> System.halt(reason)
        data -> data
      end

    data
    |> SenseWrapper.process()
    |> IO.puts()

    run()
  end
end
