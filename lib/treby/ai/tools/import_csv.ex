defmodule Treby.AI.Tools.ImportCsv do
  @moduledoc "Destructive tool: bulk-import candidates from CSV text."

  alias Treby.AI.Tools

  def name, do: "import_candidates_csv"

  def description,
    do:
      "Bulk-create candidates from CSV text (columns: name,email[,phone,linkedin_url]). First row may be a header."

  def destructive?, do: true

  def required_role, do: :admin

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
    with :ok <- Tools.authorize(__MODULE__, ctx),
         {:ok, lines} <- Treby.CsvImport.parse_lines(args["csv_text"]) do
      rows =
        lines
        |> Enum.reject(&(match?([], &1) or Enum.all?(&1, fn cell -> cell == "" end)))
        |> then(fn rows -> if args["has_header"], do: tl(rows), else: rows end)

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
  end

  defp parse_row([name, email]) when name != "" and email != "" do
    {:ok, %{"name" => name, "email" => email}}
  end

  defp parse_row([name, email | rest]) when name != "" and email != "" do
    attrs = %{"name" => name, "email" => email}
    attrs = if Enum.at(rest, 0), do: Map.put(attrs, "phone", Enum.at(rest, 0)), else: attrs

    attrs =
      if Enum.at(rest, 1), do: Map.put(attrs, "linkedin_url", Enum.at(rest, 1)), else: attrs

    {:ok, attrs}
  end

  defp parse_row(_), do: :skip
end
