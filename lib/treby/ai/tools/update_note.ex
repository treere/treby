defmodule Treby.AI.Tools.UpdateNote do
  @moduledoc "Destructive tool: update a note (author or admin)."

  alias Treby.AI.Tools

  @fields ~w(content type rating)

  def name, do: "update_note"

  def description, do: "Update a note's content, type or rating."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "note_id" => %{"type" => "string"},
        "content" => %{"type" => "string"},
        "type" => %{"type" => "string", "enum" => ["note", "feedback", "interview_feedback"]},
        "rating" => %{"type" => "integer"}
      },
      "required" => ["note_id"]
    }
  end

  def summary(args) do
    %{
      title: "Update note",
      fields: [
        {"Note", args["note_id"]},
        {"Content", args["content"]},
        {"Type", args["type"]},
        {"Rating", args["rating"]}
      ]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      note = Treby.Notes.get_note!(ctx[:tenant_id], args["note_id"])

      if own_or_admin?(note, ctx) do
        case Treby.Notes.update_note(note, Map.take(args, @fields)) do
          {:ok, updated} -> {:ok, %{"id" => updated.id}}
          {:error, reason} -> {:error, Tools.format_errors(reason)}
        end
      else
        {:error, :unauthorized}
      end
    end
  rescue
    Ecto.NoResultsError -> {:error, "note not found"}
  end

  defp own_or_admin?(note, ctx) do
    Tools.admin?(ctx) or (Tools.actor(ctx) && note.author_id == Tools.actor(ctx).id)
  end
end
