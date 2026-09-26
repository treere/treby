defmodule Treby.AI.Tools.ListWebhooks do
  @moduledoc "Read-only tool: list webhook subscriptions (admin)."

  def name, do: "list_webhooks"

  def description, do: "List the webhook subscriptions of the workspace."

  def destructive?, do: false

  def required_role, do: :admin

  def schema, do: %{"type" => "object", "properties" => %{}}

  def run(_args, ctx) do
    subs =
      ctx[:tenant_id]
      |> Treby.Webhooks.list_subscriptions()
      |> Enum.map(fn s ->
        %{
          "id" => s.id,
          "target_url" => s.target_url,
          "events" => s.events,
          "active" => s.active,
          "description" => s.description
        }
      end)

    {:ok, subs}
  end
end
