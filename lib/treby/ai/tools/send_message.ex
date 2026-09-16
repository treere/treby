defmodule Treby.AI.Tools.SendMessage do
  @moduledoc "Destructive tool: send an immediate message to a candidate conversation."

  alias Treby.AI.Tools

  def name, do: "send_message"

  def description, do: "Send a message to a candidate through their portal conversation."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "conversation_id" => %{"type" => "string"},
        "body" => %{"type" => "string", "description" => "Message text"}
      },
      "required" => ["conversation_id", "body"]
    }
  end

  def run(args, ctx) do
    attrs = %{
      "conversation_id" => args["conversation_id"],
      "body" => args["body"],
      "sender_type" => "recruiter",
      "message_type" => "text",
      "tenant_id" => ctx[:tenant_id]
    }

    case Treby.CandidatePortal.send_message(attrs) do
      {:ok, message} -> {:ok, %{"id" => message.id}}
      {:error, reason} -> {:error, Tools.format_errors(reason)}
    end
  end
end
