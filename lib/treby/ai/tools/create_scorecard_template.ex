defmodule Treby.AI.Tools.CreateScorecardTemplate do
  @moduledoc "Destructive tool: create a scorecard template (admin)."

  alias Treby.AI.Tools

  def name, do: "create_scorecard_template"

  def description, do: "Create a scorecard template with a name and criteria."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "string"},
        "criteria" => %{"type" => "array", "items" => %{"type" => "object"}},
        "position" => %{"type" => "integer"}
      },
      "required" => ["name"]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      attrs = %{
        "tenant_id" => ctx[:tenant_id],
        "name" => args["name"],
        "criteria" => args["criteria"] || [],
        "position" => args["position"] || 0
      }

      case Treby.Scorecards.create_scorecard_template(attrs, Tools.actor(ctx)) do
        {:ok, template} -> {:ok, %{"id" => template.id, "name" => template.name}}
        {:error, reason} -> {:error, Tools.format_errors(reason)}
      end
    end
  end
end
