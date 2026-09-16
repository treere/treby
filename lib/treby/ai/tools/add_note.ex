defmodule Treby.AI.Tools.AddNote do
  @moduledoc "Destructive tool: add a note or scorecard to an application."

  alias Treby.AI.Tools

  def name, do: "add_note"

  def description,
    do: "Add a note, feedback or interview scorecard to a job application."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "application_id" => %{"type" => "string"},
        "content" => %{"type" => "string", "description" => "The note text"},
        "type" => %{
          "type" => "string",
          "enum" => ["note", "feedback", "interview_feedback"]
        },
        "rating" => %{"type" => "integer", "description" => "1-5 rating (optional)"}
      },
      "required" => ["application_id", "content"]
    }
  end

  def run(args, ctx) do
    attrs = %{
      "tenant_id" => ctx[:tenant_id],
      "application_id" => args["application_id"],
      "author_id" => ctx[:user] && ctx[:user].id,
      "content" => args["content"],
      "type" => args["type"] || "note",
      "rating" => args["rating"]
    }

    case Treby.Notes.create_note(attrs) do
      {:ok, note} -> {:ok, %{"id" => note.id}}
      {:error, reason} -> {:error, Tools.format_errors(reason)}
    end
  end
end
