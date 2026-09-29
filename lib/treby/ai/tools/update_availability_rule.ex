defmodule Treby.AI.Tools.UpdateAvailabilityRule do
  @moduledoc "Destructive tool: update an availability rule (owner or admin)."

  alias Treby.AI.Tools

  def name, do: "update_availability_rule"

  def description, do: "Update one of the current user's availability rules."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "rule_id" => %{"type" => "string"},
        "day_of_week" => %{"type" => "integer"},
        "start_time" => %{"type" => "string"},
        "end_time" => %{"type" => "string"}
      },
      "required" => ["rule_id"]
    }
  end

  def summary(args) do
    %{
      title: "Update availability rule",
      fields: [
        {"Rule", args["rule_id"]},
        {"Day", args["day_of_week"]},
        {"Start", args["start_time"]},
        {"End", args["end_time"]}
      ]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      rule = Treby.Availability.get_rule!(args["rule_id"])

      if own_or_admin?(rule, ctx) do
        attrs = args |> Map.take(["day_of_week", "start_time", "end_time"])

        case Treby.Availability.update_rule(rule, attrs) do
          {:ok, updated} -> {:ok, %{"id" => updated.id}}
          {:error, reason} -> {:error, Tools.format_errors(reason)}
        end
      else
        {:error, :unauthorized}
      end
    end
  rescue
    Ecto.NoResultsError -> {:error, "rule not found"}
  end

  defp own_or_admin?(rule, ctx) do
    rule.tenant_id == ctx[:tenant_id] &&
      (Tools.admin?(ctx) || rule.user_id == Tools.actor_id(ctx))
  end
end
