defmodule Treby.AI.Tools.ListDataRequests do
  @moduledoc "Read-only tool: list data-privacy requests."

  alias Treby.AI.Tools

  def name, do: "list_data_requests"

  def description,
    do: "List data export/erasure requests. Admins see all; members only their own."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "type" => %{"type" => "string", "enum" => ["export", "erasure"]},
        "status" => %{"type" => "string"}
      }
    }
  end

  def run(args, ctx) do
    opts = []

    opts = if args["type"], do: Keyword.put(opts, :type, args["type"]), else: opts
    opts = if args["status"], do: Keyword.put(opts, :status, args["status"]), else: opts

    opts =
      if Tools.admin?(ctx), do: opts, else: Keyword.put(opts, :requester_id, Tools.actor_id(ctx))

    {:ok, Treby.DataPrivacy.Requests.list_requests(ctx[:tenant_id], opts)}
  end
end
