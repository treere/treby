defmodule Treby.AI.Tools.DeleteNote do
  @moduledoc "Destructive tool: delete a note (author or admin)."

  alias Treby.AI.Tools

  def name, do: "delete_note"

  def description, do: "Delete a note from an application."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{"note_id" => %{"type" => "string"}},
      "required" => ["note_id"]
    }
  end

  def summary(args) do
    %{
      title: "Delete note",
      fields: [
        {"Note", args["note_id"]}
      ]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      note = Treby.Notes.get_note!(ctx[:tenant_id], args["note_id"])

      if own_or_admin?(note, ctx) do
        case Treby.Notes.delete_note(note) do
          {:ok, deleted} -> {:ok, %{"id" => deleted.id}}
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
