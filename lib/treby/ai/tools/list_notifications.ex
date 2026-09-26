defmodule Treby.AI.Tools.ListNotifications do
  @moduledoc "Read-only tool: list the user's inbox notifications."

  def name, do: "list_notifications"

  def description, do: "List the current user's inbox notifications, newest first."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "limit" => %{"type" => "integer"},
        "unread_only" => %{"type" => "boolean"}
      }
    }
  end

  def run(args, ctx) do
    opts = [limit: args["limit"] || 20, filter: if(args["unread_only"], do: :unread, else: :all)]

    notifications =
      Treby.Notifications.Inbox.list_for_user(
        Treby.AI.Tools.actor_id(ctx),
        ctx[:tenant_id],
        opts
      )

    {:ok, notifications}
  end
end
