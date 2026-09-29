defmodule Treby.AI.Tools.UpdateWebhook do
  @moduledoc "Destructive tool: update a webhook subscription (admin)."

  alias Treby.AI.Tools

  def name, do: "update_webhook"

  def description, do: "Update a webhook subscription's URL, events, description or active flag."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "webhook_id" => %{"type" => "string"},
        "target_url" => %{"type" => "string"},
        "events" => %{"type" => "array", "items" => %{"type" => "string"}},
        "description" => %{"type" => "string"},
        "active" => %{"type" => "boolean"}
      },
      "required" => ["webhook_id"]
    }
  end

  def summary(args) do
    %{
      title: "Update webhook",
      fields: [
        {"Webhook", args["webhook_id"]},
        {"Target URL", args["target_url"]},
        {"Events", args["events"]},
        {"Description", args["description"]},
        {"Active", args["active"]}
      ]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      case Treby.Webhooks.get_subscription(ctx[:tenant_id], args["webhook_id"]) do
        nil ->
          {:error, "webhook not found"}

        sub ->
          attrs =
            %{}
            |> maybe_put("target_url", args["target_url"])
            |> maybe_put("description", args["description"])
            |> maybe_put("active", args["active"])
            |> maybe_put("events_text", events_text(args["events"]))

          case sub
               |> Treby.Webhooks.update_subscription(attrs)
               |> Treby.Webhooks.save_subscription() do
            {:ok, updated} -> {:ok, %{"id" => updated.id}}
            {:error, reason} -> {:error, Tools.format_errors(reason)}
          end
      end
    end
  end

  defp events_text(nil), do: nil
  defp events_text(events), do: Enum.join(events, " ")

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
