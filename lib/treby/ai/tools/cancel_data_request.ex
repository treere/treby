defmodule Treby.AI.Tools.CancelDataRequest do
  @moduledoc "Destructive tool: cancel a data-privacy request."

  alias Treby.AI.Tools

  def name, do: "cancel_data_request"

  def description, do: "Cancel a pending data export or erasure request."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{"request_id" => %{"type" => "string"}},
      "required" => ["request_id"]
    }
  end

  def summary(args) do
    %{
      title: "Cancel data request",
      fields: [
        {"Request", args["request_id"]}
      ]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      request = Treby.DataPrivacy.Requests.get_request!(ctx[:tenant_id], args["request_id"])

      if Tools.admin?(ctx) or request.requester_id == Tools.actor_id(ctx) do
        case Treby.DataPrivacy.Requests.cancel(request) do
          {:ok, cancelled} -> {:ok, %{"id" => cancelled.id, "status" => cancelled.status}}
          {:error, reason} -> {:error, Tools.format_errors(reason)}
        end
      else
        {:error, :unauthorized}
      end
    end
  rescue
    Ecto.NoResultsError -> {:error, "request not found"}
  end
end
