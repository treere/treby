defmodule Treby.AI.Tools.UpdateScorecardTemplate do
  @moduledoc "Destructive tool: update a scorecard template (admin)."

  alias Treby.AI.Tools

  def name, do: "update_scorecard_template"

  def description, do: "Update the name, criteria or position of a scorecard template."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "template_id" => %{"type" => "string"},
        "name" => %{"type" => "string"},
        "criteria" => %{"type" => "array", "items" => %{"type" => "object"}},
        "position" => %{"type" => "integer"}
      },
      "required" => ["template_id"]
    }
  end

  def summary(args) do
    %{
      title: "Update scorecard template",
      fields: [
        {"Template", args["template_id"]},
        {"Name", args["name"]},
        {"Criteria", args["criteria"]},
        {"Position", args["position"]}
      ]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      template = Treby.Scorecards.get_scorecard_template!(args["template_id"])

      if template.tenant_id == ctx[:tenant_id] do
        attrs = args |> Map.take(["name", "criteria", "position"])

        case Treby.Scorecards.update_scorecard_template(template, attrs, Tools.actor(ctx)) do
          {:ok, updated} -> {:ok, %{"id" => updated.id}}
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
