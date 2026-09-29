defmodule Treby.AI.Tools.SetNotificationPreference do
  @moduledoc "Destructive tool: change a notification preference (admin)."

  alias Treby.AI.Tools

  def name, do: "set_notification_preference"

  def description, do: "Set an email/inbox notification preference for an event type."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "key" => %{
          "type" => "string",
          "enum" => [
            "stage_change_candidate",
            "new_application_candidate",
            "new_application_team",
            "interview_reminder"
          ]
        },
        "email" => %{"type" => "boolean"},
        "inbox" => %{"type" => "boolean"}
      },
      "required" => ["key"]
    }
  end

  def summary(args) do
    %{
      title: "Update notification preference",
      fields: [
        {"Key", args["key"]},
        {"Email", args["email"]},
        {"Inbox", args["inbox"]}
      ]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      tenant = Treby.Tenants.get_tenant!(ctx[:tenant_id])

      value = %{"email" => args["email"] != false, "inbox" => args["inbox"] != false}

      case Treby.Notifications.set_notification_preference(tenant, args["key"], value) do
        {:ok, updated} ->
          {:ok, %{"key" => args["key"], "settings" => updated.settings["notifications"]}}

        {:error, reason} ->
          {:error, Tools.format_errors(reason)}
      end
    end
  end
end
