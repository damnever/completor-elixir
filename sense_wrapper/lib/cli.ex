defmodule SenseWrapper.CLI do
  def main(_args \\ []) do
    process()
  end

  defp process() do
    data = case IO.read(:line) do
      :eof -> System.halt(0)
      {:error, reason} -> System.halt(reason)
      data -> data
    end

    data
    |> SenseWrapper.process
    |> IO.puts

    process()
  end
end
