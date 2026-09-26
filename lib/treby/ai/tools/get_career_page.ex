defmodule Treby.AI.Tools.GetCareerPage do
  @moduledoc "Read-only tool: read the workspace career page."

  def name, do: "get_career_page"

  def description, do: "Read the public career page of the workspace."

  def destructive?, do: false

  def schema, do: %{"type" => "object", "properties" => %{}}

  def run(_args, ctx) do
    case Treby.Careers.get_career_page_by_tenant(ctx[:tenant_id]) do
      nil -> {:ok, %{}}
      page -> {:ok, page}
    end
  end
end
