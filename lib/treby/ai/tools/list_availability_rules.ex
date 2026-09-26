defmodule Treby.AI.Tools.ListAvailabilityRules do
  @moduledoc "Read-only tool: list availability rules."

  def name, do: "list_availability_rules"

  def description, do: "List the current user's availability rules, or the company-wide ones."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "scope" => %{"type" => "string", "enum" => ["user", "company"]}
      }
    }
  end

  def run(args, ctx) do
    rules =
      case args["scope"] do
        "company" -> Treby.Availability.list_company_rules(ctx[:tenant_id])
        _ -> Treby.Availability.list_rules_for_user(Treby.AI.Tools.actor_id(ctx))
      end

    {:ok,
     Enum.map(rules, fn r ->
       %{
         "id" => r.id,
         "day_of_week" => r.day_of_week,
         "start_time" => r.start_time,
         "end_time" => r.end_time,
         "scope" => r.scope
       }
     end)}
  end
end
