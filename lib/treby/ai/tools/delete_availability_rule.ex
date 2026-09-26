defmodule Treby.AI.Tools.DeleteAvailabilityRule do
  @moduledoc "Destructive tool: delete an availability rule (owner or admin)."

  alias Treby.AI.Tools

  def name, do: "delete_availability_rule"

  def description, do: "Delete one of the current user's availability rules."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{"rule_id" => %{"type" => "string"}},
      "required" => ["rule_id"]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      rule = Treby.Availability.get_rule!(args["rule_id"])

      if own_or_admin?(rule, ctx) do
        case Treby.Availability.delete_rule(rule) do
          {:ok, deleted} -> {:ok, %{"id" => deleted.id}}
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
