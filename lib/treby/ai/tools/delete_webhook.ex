defmodule Treby.AI.Tools.DeleteWebhook do
  @moduledoc "Destructive tool: delete a webhook subscription (admin)."

  alias Treby.AI.Tools

  def name, do: "delete_webhook"

  def description, do: "Delete a webhook subscription of the workspace."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{"webhook_id" => %{"type" => "string"}},
      "required" => ["webhook_id"]
    }
  end

  def summary(args) do
    %{
      title: "Delete webhook",
      fields: [
        {"Webhook", args["webhook_id"]}
      ]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      case Treby.Webhooks.get_subscription(ctx[:tenant_id], args["webhook_id"]) do
        nil ->
          {:error, "webhook not found"}

        sub ->
          case Treby.Webhooks.delete_subscription(sub) do
            {:ok, deleted} -> {:ok, %{"id" => deleted.id}}
            {:error, reason} -> {:error, Tools.format_errors(reason)}
          end
      end
    end
  end
end
