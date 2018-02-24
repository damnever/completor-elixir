defmodule SenseWrapperTest do
  use ExUnit.Case, async: false
  doctest SenseWrapper

  @code ~S"""
defmodule MyModule do
  alias Enum, as: MyEnum
  MyEnum.to_list(1..3)
end
"""

  test "doc" do
    code = ~S"""
defmodule MyModule do
  String.split("hello")
end
"""
    output("doc", Poison.encode!(%{type: "doc", ctx: nil, code: code, line: 1, column: 2}))
  end

  test "definition" do
    output("definition", Poison.encode!(%{type: "definition", ctx: nil, code: @code, line: 3, column: 11}))
  end

  test "complete2" do
    code = ~S"""
defmodule MyModule do
  Applica
end
"""
    output("complete2", Poison.encode!(%{type: "complete", ctx: nil, code: code, line: 2, column: 12}))
  end

  test "complete" do
    code = ~S"""
defmodule MyModule do
  alias Enum, as: MyEnum
  MyEnum.to_l
end
"""
    output("complete", Poison.encode!(%{type: "complete", ctx: nil, code: code, line: 3, column: 14}))
  end


  test "signature" do
    code = ~S"""
defmodule MyModule do
  alias Enum, as: MyEnum
  MyEnum.flatten(par0,
end
"""
    output("signature", Poison.encode!(%{type: "signature", ctx: nil, code: code, line: 3, column: 23}))
  end

  defp output(t, input) do
    IO.puts("========#{t}==========")
    input
    |> SenseWrapper.process
    |> IO.puts
    IO.puts("========================")
  end
end
