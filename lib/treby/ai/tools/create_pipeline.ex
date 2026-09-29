defmodule Treby.AI.Tools.CreatePipeline do
  @moduledoc "Destructive tool: create a pipeline."

  alias Treby.AI.Tools

  def name, do: "create_pipeline"

  def description, do: "Create a new pipeline in the workspace."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "string"},
        "is_default" => %{"type" => "boolean"}
      },
      "required" => ["name"]
    }
  end

  def summary(args) do
    %{
      title: "Create pipeline",
      fields: [
        {"Name", args["name"]},
        {"Default", args["is_default"]}
      ]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      attrs = %{"tenant_id" => ctx[:tenant_id], "name" => args["name"]}

      attrs =
        if Map.has_key?(args, "is_default"),
          do: Map.put(attrs, "is_default", args["is_default"]),
          else: attrs

      case Treby.Pipeline.create_pipeline(attrs) do
        {:ok, pipeline} -> {:ok, %{"id" => pipeline.id, "name" => pipeline.name}}
        {:error, reason} -> {:error, Tools.format_errors(reason)}
      end
    end
  end
end
