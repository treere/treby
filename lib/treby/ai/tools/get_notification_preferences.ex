defmodule Treby.AI.Tools.GetNotificationPreferences do
  @moduledoc "Read-only tool: read the workspace notification preferences."

  def name, do: "get_notification_preferences"

  def description, do: "Read the workspace notification preferences (email/inbox per event type)."

  def destructive?, do: false

  def schema, do: %{"type" => "object", "properties" => %{}}

  def run(_args, ctx) do
    tenant = Treby.Tenants.get_tenant!(ctx[:tenant_id])
    {:ok, Treby.Notifications.notification_preferences(tenant)}
  end
end
