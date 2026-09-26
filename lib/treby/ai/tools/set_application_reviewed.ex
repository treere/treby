defmodule Treby.AI.Tools.SetApplicationReviewed do
  @moduledoc "Destructive tool: mark an application reviewed or unreviewed."

  alias Treby.AI.Tools

  def name, do: "set_application_reviewed"

  def description, do: "Mark a job application as reviewed or unreviewed."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "id" => %{"type" => "string", "description" => "Application id"},
        "reviewed" => %{"type" => "boolean", "description" => "true to mark reviewed"}
      },
      "required" => ["id", "reviewed"]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      application = Treby.Pipeline.get_application!(ctx[:tenant_id], args["id"])

      result =
        if args["reviewed"],
          do: Treby.Pipeline.mark_reviewed(application),
          else: Treby.Pipeline.mark_unreviewed(application)

      case result do
        {:ok, app} -> {:ok, %{"id" => app.id, "reviewed" => app.reviewed}}
        {:error, reason} -> {:error, Tools.format_errors(reason)}
      end
    end
  rescue
    Ecto.NoResultsError -> {:error, "application not found"}
  end
end
