defmodule Treby.AI.Tools.UpdateCareerPage do
  @moduledoc "Destructive tool: update the workspace career page (admin)."

  alias Treby.AI.Tools

  @fields ~w(title description about logo_url published)

  def name, do: "update_career_page"

  def description, do: "Update the workspace career page content and visibility."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "title" => %{"type" => "string"},
        "description" => %{"type" => "string"},
        "about" => %{"type" => "string"},
        "logo_url" => %{"type" => "string"},
        "published" => %{"type" => "boolean"}
      }
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      case Treby.Careers.get_career_page_by_tenant(ctx[:tenant_id]) do
        nil ->
          {:error, "career page not found"}

        page ->
          case Treby.Careers.update_career_page(page, Map.take(args, @fields)) do
            {:ok, updated} -> {:ok, %{"id" => updated.id}}
            {:error, reason} -> {:error, Tools.format_errors(reason)}
          end
      end
    end
  end
end
