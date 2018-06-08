defmodule SenseWrapper do
  @moduledoc """
  Wrapper for elixir_sense.
  """
  alias ElixirSense.Server.ContextLoader

  @doc """
  input JSON string like this:
  {
    "type": "doc"/"definition"/"complete"/"signature",
    "ctx": nil/{"env": "dev"/"test", "cwd": "/path/to/project"},
    "code": "code snippet",
    "line": number,
    "column": number
  }
  output JSON string like this:
  {
    "data"/"error": data/"reason",
  }
  """
  @spec process(String.t) :: String.t
  def process("ping") do
    "pong"
  end

  def process(input) do
    with {:ok, req} <- Poison.decode(input),
         {:ok, resp} <- dispatch_request(req),
         {:ok, output} <- Poison.encode(%{"data" => resp})
    do
      output
    else
      {:error, reason} -> Poison.encode!(%{"error" => "#{inspect(reason)}"})
      what -> Poison.encode!(%{"error" => "#{inspect(what)}"})
    end
  end


  defp dispatch_request(%{
    "type" => type,
    "ctx" => ctx,
    "code" => code,
    "line" => line,
    "column" => column
  }) do
    if ctx do
      %{"env" => env, "cwd" => cwd} = ctx
      # TODO(damnever): set context only if context changed
      # credo:disable-for-previous-line
      ContextLoader.set_context(env, cwd)
    end

    handle_request(type, code, line, column)
  end

  defp dispatch_request(_req) do
    {:error, "bad request"}
  end


  defp handle_request("doc", code, line, column) do
    %{
      actual_subject: actual_subject,
      docs: docs
    } = ElixirSense.docs(code, line, column)

    docs =
      case docs do
        %{types: _, docs: docs, callbacks: callbacks} ->
          actual_subject <> "\n\n" <> docs <> "\n\n" <> callbacks

        %{types: _, docs: docs} ->
          actual_subject <> "\n\n" <> docs

        _ ->
          actual_subject
      end

    {:ok, docs}
  end

  defp handle_request("definition", code, line, column) do
    loc = ElixirSense.definition(code, line, column)
    if loc.found do
      {:ok, %{"filename" => loc.file, "line" => loc.line, "column" => loc.column}}
    else
      {:error, "definition not found"}
    end
  end

  defp handle_request("complete", code, line, column) do
    suggestions = ElixirSense.suggestions(code, line, column)
    [hint | suggestions] = suggestions

    mod =
      if String.ends_with?(hint.value, ".") do
          hint.value
      else
        ""
      end

    {:ok, %{
      "module" => mod,
      "suggestions" => parse_suggestions([], mod, suggestions) |> Enum.reverse,
    }}
  end

  defp handle_request("signature", code, line, column) do
    {:ok, ElixirSense.signature(code, line, column)}
  end


  defp parse_suggestions(suggestions, mod, [sugg | rest]) do
    case sugg.type do
      :module ->
        [parse_mod_suggestion(mod, sugg) | suggestions]

      "function" ->
        [parse_func_suggestion(mod, sugg) | suggestions]

      _ ->
        suggestions
    end
    |> parse_suggestions(mod, rest)
    # credo:disable-for-previous-line
  end

  defp parse_suggestions(suggestions, _mod, []) do
    suggestions
  end

  defp parse_mod_suggestion(_mod, sugg) do
    kind =
      if sugg.subtype do
        sugg.subtype
      else
        sugg.type
      end |> Atom.to_string
    # credo:disable-for-previous-line

    %{
      "kind" => kind,
      "word" => sugg.name,
      "abbr" => sugg.name,
      "menu" => "",
      "info" => sugg.summary,
    }
  end

  defp parse_func_suggestion(mod, sugg) do
    sign =
      if sugg.args != "" do
        args = sugg.args |> String.split(",") |> Enum.join(", ")
        mod <> sugg.name <> "(" <> args <> ")"
      else
        mod <> sugg.name <> "/" <> Integer.to_string(sugg.arity)
      end

    info =
      cond do
        sugg.summary != "" and sugg.spec != "" ->
          String.trim(sugg.spec) <> "\n" <> String.trim(sugg.summary)

        sugg.spec != "" ->
          sugg.spec

        sugg.summary != "" ->
          sugg.summary

        true ->
          ""
      end

    %{
      "kind" => "func",
      "word" => sugg.name,
      "abbr" => sugg.name,
      "menu" => sign,
      "info" => info,
    }
  end
end
