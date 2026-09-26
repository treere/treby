defmodule Treby.AI.Tools.PreviewCsvImport do
  @moduledoc "Read-only tool: preview a candidate CSV import."

  alias Treby.AI.Tools

  def name, do: "preview_csv_import"

  def description,
    do: "Parse CSV text and preview the first rows, detecting column mapping and duplicates."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{"csv_text" => %{"type" => "string", "description" => "CSV content"}},
      "required" => ["csv_text"]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx),
         {:ok, %{rows: rows, headers: headers}} <- Treby.CsvImport.parse_csv(args["csv_text"]),
         {:ok, mapping} <- Treby.CsvImport.auto_detect_mapping(headers),
         {:ok, preview} <- Treby.CsvImport.preview_import(rows, mapping, ctx[:tenant_id]) do
      {:ok,
       %{
         "headers" => headers,
         "mapping" => mapping,
         "rows_total" => length(rows),
         "preview" => Enum.map(preview, &sanitize_preview/1)
       }}
    end
  end

  defp sanitize_preview(item) do
    %{
      "candidate" => item.candidate_attrs,
      "is_duplicate" => item.is_duplicate,
      "validation" => inspect(item.validation)
    }
  end
end
