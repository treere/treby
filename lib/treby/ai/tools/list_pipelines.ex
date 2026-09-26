defmodule Treby.AI.Tools.ListPipelines do
  @moduledoc "Read-only tool: list the workspace pipelines and their stages."

  def name, do: "list_pipelines"

  def description, do: "List the pipelines of the workspace with their stages."

  def destructive?, do: false

  def schema, do: %{"type" => "object", "properties" => %{}}

  def run(_args, ctx) do
    pipelines =
      ctx[:tenant_id]
      |> Treby.Pipeline.list_pipelines()
      |> Enum.map(fn p ->
        %{
          "id" => p.id,
          "name" => p.name,
          "is_default" => p.is_default,
          "stages" =>
            Enum.map(p.pipeline_stages, fn s ->
              %{"id" => s.id, "name" => s.name, "position" => s.position}
            end)
        }
      end)

    {:ok, pipelines}
  end
end
