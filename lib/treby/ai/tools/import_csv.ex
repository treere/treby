defmodule Treby.AI.Tools.ImportCsv do
  @moduledoc "Destructive tool: bulk-import candidates from CSV text."

  def name, do: "import_candidates_csv"

  def description,
    do:
      "Bulk-create candidates from CSV text (columns: name,email[,phone,linkedin_url]). First row may be a header."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "csv_text" => %{"type" => "string", "description" => "CSV content"},
        "has_header" => %{"type" => "boolean", "description" => "Skip the first row if true"}
      },
      "required" => ["csv_text"]
    }
  end

  def run(args, ctx) do
    rows =
      args["csv_text"]
      |> String.split(~r/\R/)
      |> Enum.reject(&(&1 |> String.trim() == ""))
      |> then(fn lines -> if args["has_header"], do: tl(lines), else: lines end)

    {created, errors} =
      Enum.reduce(rows, {0, []}, fn line, {ok, errs} ->
        case parse_row(line) do
          {:ok, attrs} ->
            case Treby.Candidates.create_or_find(ctx[:tenant_id], attrs) do
              {:ok, _} -> {ok + 1, errs}
              {:error, reason} -> {ok, [reason | errs]}
            end

          :skip ->
            {ok, errs}
        end
      end)

    {:ok, %{"created" => created, "errors" => Enum.reverse(errors)}}
  end

  defp parse_row(line) do
    case line |> String.split(~r/,/) |> Enum.map(&String.trim/1) do
      [name, email] when name != "" and email != "" ->
        {:ok, %{"name" => name, "email" => email}}

      [name, email | rest] when name != "" and email != "" ->
        attrs = %{"name" => name, "email" => email}
        attrs = if Enum.at(rest, 0), do: Map.put(attrs, "phone", Enum.at(rest, 0)), else: attrs

        attrs =
          if Enum.at(rest, 1), do: Map.put(attrs, "linkedin_url", Enum.at(rest, 1)), else: attrs

        {:ok, attrs}

      _ ->
        :skip
    end
  end
end
