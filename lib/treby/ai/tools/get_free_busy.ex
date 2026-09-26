defmodule Treby.AI.Tools.GetFreeBusy do
  @moduledoc "Read-only tool: fetch the user's busy periods."

  def name, do: "get_free_busy"

  def description,
    do: "Fetch the current user's busy periods over a time range, from their calendar provider."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "provider" => %{"type" => "string", "enum" => ["google", "treby"]},
        "time_min" => %{"type" => "string", "description" => "ISO8601 UTC"},
        "time_max" => %{"type" => "string", "description" => "ISO8601 UTC"}
      },
      "required" => ["provider", "time_min", "time_max"]
    }
  end

  def run(args, ctx) do
    with {:ok, time_min} <- parse_datetime(args["time_min"]),
         {:ok, time_max} <- parse_datetime(args["time_max"]) do
      user_id = Treby.AI.Tools.actor_id(ctx)

      case Treby.Calendar.get_free_busy(user_id, args["provider"], time_min, time_max) do
        {:ok, busy} -> {:ok, busy}
        {:error, reason} -> {:error, inspect(reason)}
      end
    end
  end

  defp parse_datetime(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _} -> {:ok, dt}
      _ -> {:error, "invalid datetime; use ISO8601 UTC"}
    end
  end
end
