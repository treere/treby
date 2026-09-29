defmodule Treby.AI.Tools.TestWebhook do
  @moduledoc "Destructive tool: send a test ping to a webhook (admin)."

  alias Treby.AI.Tools

  def name, do: "test_webhook"

  def description, do: "Send a test ping to a webhook subscription and report the HTTP status."

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
      title: "Test webhook",
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
          case Treby.Webhooks.test_ping(sub.target_url, sub.secret) do
            {:ok, status} -> {:ok, %{"delivered" => true, "status" => status}}
            {:error, reason} -> {:error, reason}
          end
      end
    end
  end
end
