defmodule Treby.AI.Tools.MoveApplication do
  @moduledoc "Destructive tool: move an application to another pipeline stage."

  alias Treby.AI.Tools

  def name, do: "move_application"

  def description, do: "Advance or move a job application to a different pipeline stage."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "id" => %{"type" => "string", "description" => "Application id"},
        "stage_id" => %{"type" => "string", "description" => "Target pipeline stage id"}
      },
      "required" => ["id", "stage_id"]
    }
  end

  def run(args, _ctx) do
    case Treby.Pipeline.get_application(args["id"]) do
      nil ->
        {:error, "application not found"}

      application ->
        case Treby.Pipeline.move_application(application, args["stage_id"], []) do
          {:ok, _} -> {:ok, %{"id" => application.id, "stage_id" => args["stage_id"]}}
          {:error, reason} -> {:error, Tools.format_errors(reason)}
        end
    end
  end
end
