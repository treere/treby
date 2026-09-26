defmodule Treby.AI.Tools.ListNotes do
  @moduledoc "Read-only tool: list notes on an application."

  def name, do: "list_notes"

  def description, do: "List the notes and feedback on a job application."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{"application_id" => %{"type" => "string"}},
      "required" => ["application_id"]
    }
  end

  def run(args, ctx) do
    application = Treby.Pipeline.get_application!(ctx[:tenant_id], args["application_id"])

    notes =
      application.id
      |> Treby.Notes.list_notes_for_application()
      |> Enum.map(fn n ->
        %{
          "id" => n.id,
          "content" => n.content,
          "type" => n.type,
          "rating" => n.rating,
          "author_id" => n.author_id
        }
      end)

    {:ok, notes}
  rescue
    Ecto.NoResultsError -> {:error, "application not found"}
  end
end
