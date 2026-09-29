defmodule Treby.AI.Tools.CreateDataRequest do
  @moduledoc "Destructive tool: create a data export or erasure request."

  alias Treby.AI.Tools

  def name, do: "create_data_request"

  def description, do: "Request a data export or erasure. Tenant-wide erasure requires admin."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "type" => %{"type" => "string", "enum" => ["export", "erasure"]},
        "scope" => %{"type" => "string", "enum" => ["user", "tenant"]}
      },
      "required" => ["type", "scope"]
    }
  end

  def summary(args) do
    %{
      title: "Create data request",
      fields: [
        {"Type", args["type"]},
        {"Scope", args["scope"]}
      ]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx),
         :ok <- require_tenant_admin(args["scope"], ctx) do
      attrs = %{
        "tenant_id" => ctx[:tenant_id],
        "requester_id" => Tools.actor_id(ctx),
        "type" => args["type"],
        "scope" => args["scope"],
        "status" => "pending"
      }

      case Treby.DataPrivacy.Requests.create_request(attrs) do
        {:ok, request} -> {:ok, %{"id" => request.id, "status" => request.status}}
        {:error, reason} -> {:error, Tools.format_errors(reason)}
      end
    end
  end

  defp require_tenant_admin("tenant", ctx) do
    if Tools.admin?(ctx), do: :ok, else: {:error, :unauthorized}
  end

  defp require_tenant_admin(_scope, _ctx), do: :ok
end
