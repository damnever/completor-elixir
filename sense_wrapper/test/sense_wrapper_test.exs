defmodule SenseWrapperTest do
  use ExUnit.Case, async: false
  doctest SenseWrapper

  test "ping" do
    assert("pong" == SenseWrapper.process("ping"))
  end

  test "doc" do
    code = ~S"""
defmodule M do
  String.split("hello")
end
"""
    %{"data" => data} = process(%{type: "doc", ctx: nil, code: code, line: 2, column: 12})
    doc = data |> String.split("\n") |> Enum.at(2)
    assert "> String.split(binary)" == doc
  end

  test "definition" do
    code = ~S"""
defmodule M do
  def xx do
  end
end
"""
    %{
      "error" => "\"definition not found\""
    } = process(%{type: "definition", ctx: nil, code: code, line: 2, column: 8})
  end

  test "complete module" do
    code = ~S"""
defmodule MyModule do
  use Applica
end
"""
    %{
      "data" => %{
        "module" => module,
        "suggestions" => suggestions,
      },
    } = process(%{type: "complete", ctx: nil, code: code, line: 2, column: 14})

    assert "Application." == module
    %{
      "abbr" => "Application",
      "info" => "A module for working with applications and defining application callbacks.",
      "kind" => "module",
      "menu" => "",
      "word" => "Application",
    } = hd(suggestions)
  end

  test "complete function" do
    code = ~S"""
defmodule MyModule do
  alias Enum, as: MyEnum
  MyEnum.to_l
end
"""
    %{
      "data" => %{
        "module" => module,
        "suggestions" => suggestions,
      },
    } = process(%{type: "complete", ctx: nil, code: code, line: 3, column: 14})

    assert "" == module
    %{
      "abbr" => "to_list",
      "info" => "@spec to_list(t) :: [element]\nConverts `enumerable` to a list.",
      "kind" => "func",
      "menu" => "to_list(enumerable)",
      "word" => "to_list"
    } = hd(suggestions)
  end

  defp process(input) do
    input |> Poison.encode! |> SenseWrapper.process |> Poison.decode!
  end
end
