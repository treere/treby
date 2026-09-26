defmodule Treby.AI.Tools.DeleteCustomField do
  @moduledoc "Destructive tool: delete a custom field (admin)."

  alias Treby.AI.Tools

  def name, do: "delete_custom_field"

  def description, do: "Delete a custom field of the workspace."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{"field_id" => %{"type" => "string"}},
      "required" => ["field_id"]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      field = Treby.Customization.get_custom_field!(ctx[:tenant_id], args["field_id"])

      case Treby.Customization.delete_custom_field(field, Tools.actor(ctx)) do
        {:ok, deleted} -> {:ok, %{"id" => deleted.id}}
        {:error, reason} -> {:error, Tools.format_errors(reason)}
      end
    end
  rescue
    Ecto.NoResultsError -> {:error, "custom field not found"}
  end
end
