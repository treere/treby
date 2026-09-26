defmodule Treby.AI.Tools.CreateWebhook do
  @moduledoc "Destructive tool: create a webhook subscription (admin)."

  alias Treby.AI.Tools

  def name, do: "create_webhook"

  def description, do: "Create a webhook subscription for one or more audit events."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "target_url" => %{"type" => "string"},
        "events" => %{"type" => "array", "items" => %{"type" => "string"}},
        "description" => %{"type" => "string"},
        "active" => %{"type" => "boolean"}
      },
      "required" => ["target_url", "events"]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      attrs = %{
        "target_url" => args["target_url"],
        "events_text" => Enum.join(args["events"], " "),
        "description" => args["description"] || "",
        "active" => args["active"] != false
      }

      case ctx[:tenant_id]
           |> Treby.Webhooks.create_subscription(attrs)
           |> Treby.Webhooks.save_subscription() do
        {:ok, sub} -> {:ok, %{"id" => sub.id}}
        {:error, reason} -> {:error, Tools.format_errors(reason)}
      end
    end
  end
end
