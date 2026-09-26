defmodule Treby.AI.Tools.CreateAvailabilityRule do
  @moduledoc "Destructive tool: create an availability rule."

  alias Treby.AI.Tools

  def name, do: "create_availability_rule"

  def description,
    do: "Create the current user's availability rule, or a company-wide one (admins only)."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "day_of_week" => %{"type" => "integer", "description" => "0=Sunday .. 6=Saturday"},
        "start_time" => %{"type" => "string", "description" => "HH:MM"},
        "end_time" => %{"type" => "string", "description" => "HH:MM"},
        "scope" => %{"type" => "string", "enum" => ["user", "company"]}
      },
      "required" => ["day_of_week", "start_time", "end_time"]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx),
         :ok <- require_company_admin(args["scope"], ctx) do
      attrs = %{
        "tenant_id" => ctx[:tenant_id],
        "day_of_week" => args["day_of_week"],
        "start_time" => args["start_time"],
        "end_time" => args["end_time"],
        "scope" => args["scope"] || "user"
      }

      attrs =
        if attrs["scope"] == "user",
          do: Map.put(attrs, "user_id", Tools.actor_id(ctx)),
          else: attrs

      case Treby.Availability.create_rule(attrs) do
        {:ok, rule} -> {:ok, %{"id" => rule.id}}
        {:error, reason} -> {:error, Tools.format_errors(reason)}
      end
    end
  end

  defp require_company_admin("company", ctx) do
    if Tools.admin?(ctx), do: :ok, else: {:error, :unauthorized}
  end

  defp require_company_admin(_scope, _ctx), do: :ok
end
