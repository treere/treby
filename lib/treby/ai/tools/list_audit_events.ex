defmodule Treby.AI.Tools.ListAuditEvents do
  @moduledoc "Read-only tool: list the workspace audit log (admin)."

  def name, do: "list_audit_events"

  def description, do: "List the immutable audit log events of the workspace."

  def destructive?, do: false

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "action" => %{"type" => "string", "description" => "Optional action filter"},
        "limit" => %{"type" => "integer"}
      }
    }
  end

  def run(args, ctx) do
    opts =
      [limit: args["limit"] || 50]
      |> maybe_put_action(args["action"])

    {events, _meta} = Treby.Audit.list_events(ctx[:tenant_id], opts)
    {:ok, events}
  end

  defp maybe_put_action(opts, nil), do: opts
  defp maybe_put_action(opts, action), do: Keyword.put(opts, :action, action)
end
