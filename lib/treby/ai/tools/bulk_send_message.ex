defmodule Treby.AI.Tools.BulkSendMessage do
  @moduledoc "Destructive tool: send a message to many candidates."

  alias Treby.AI.Tools

  def name, do: "bulk_send_message"

  def description, do: "Send a message to the candidates of multiple applications at once."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "application_ids" => %{"type" => "array", "items" => %{"type" => "string"}},
        "body" => %{"type" => "string"}
      },
      "required" => ["application_ids", "body"]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      {:ok, result} =
        Treby.BulkOperations.bulk_send_message(
          args["application_ids"],
          args["body"],
          ctx[:tenant_id]
        )

      {:ok, %{"sent" => result.sent, "failed" => result.failed}}
    end
  end
end
