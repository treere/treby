defmodule Treby.AI.Tools.UpdateSettings do
  @moduledoc "Destructive tool: update workspace settings."

  alias Treby.AI.Tools

  def name, do: "update_settings"

  def description, do: "Update the workspace name or other settings."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "string", "description" => "Workspace name"}
      }
    }
  end

  def run(args, ctx) do
    unless Map.has_key?(args, "name") and args["name"] != "" do
      {:error, "nothing to update"}
    else
      tenant = Treby.Tenants.get_tenant!(ctx[:tenant_id])

      case Treby.Tenants.update_tenant(tenant, %{"name" => args["name"]}) do
        {:ok, updated} -> {:ok, %{"id" => updated.id, "name" => updated.name}}
        {:error, reason} -> {:error, Tools.format_errors(reason)}
      end
    end
  end
end
