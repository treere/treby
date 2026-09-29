defmodule Treby.AI.Tools.DeleteScorecardTemplate do
  @moduledoc "Destructive tool: delete a scorecard template (admin)."

  alias Treby.AI.Tools

  def name, do: "delete_scorecard_template"

  def description, do: "Delete a scorecard template."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{"template_id" => %{"type" => "string"}},
      "required" => ["template_id"]
    }
  end

  def summary(args) do
    %{
      title: "Delete scorecard template",
      fields: [
        {"Template", args["template_id"]}
      ]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      template = Treby.Scorecards.get_scorecard_template!(args["template_id"])

      if template.tenant_id == ctx[:tenant_id] do
        case Treby.Scorecards.delete_scorecard_template(template, Tools.actor(ctx)) do
          {:ok, deleted} -> {:ok, %{"id" => deleted.id}}
          {:error, reason} -> {:error, Tools.format_errors(reason)}
        end
      else
        {:error, "template not found"}
      end
    end
  rescue
    Ecto.NoResultsError -> {:error, "template not found"}
  end
end
