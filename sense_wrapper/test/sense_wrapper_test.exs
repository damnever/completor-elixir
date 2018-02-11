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
    output("doc", Poison.encode!(%{type: "doc", ctx: nil, code: @code, line: 3, column: 11}))
  end

  test "definition" do
    output("definition", Poison.encode!(%{type: "definition", ctx: nil, code: @code, line: 3, column: 11}))
  end

  test "complete" do
    code = ~S"""
defmodule MyModule do
  alias Enum, as: MyEnum
  MyEnu
end
"""
    output("complete", Poison.encode!(%{type: "complete", ctx: nil, code: code, line: 3, column: 8}))
  end

  test "use module" do
    code = ~S"""
    use Applica
    """
    output("complete", Poison.encode!(%{type: "complete", ctx: nil, code: code, line: 1, column: 16}))
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
