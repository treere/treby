defmodule Treby.AI.Tools.ListScheduledMessages do
  @moduledoc "Read-only tool: list scheduled messages."

  def name, do: "list_scheduled_messages"

  def description, do: "List messages scheduled, sent, failed or cancelled in the workspace."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "status" => %{"type" => "string", "enum" => ["scheduled", "sent", "failed", "cancelled"]}
      }
    }
  end

  def run(args, ctx) do
    messages =
      case args["status"] do
        "sent" -> Treby.ScheduledMessages.list_sent(ctx[:tenant_id])
        "failed" -> Treby.ScheduledMessages.list_failed(ctx[:tenant_id])
        "cancelled" -> Treby.ScheduledMessages.list_cancelled(ctx[:tenant_id])
        _ -> Treby.ScheduledMessages.list_scheduled(ctx[:tenant_id])
      end

    {:ok,
     Enum.map(messages, fn m ->
       %{
         "id" => m.id,
         "status" => m.status,
         "send_at" => m.send_at,
         "body" => m.body
       }
     end)}
  end
end
