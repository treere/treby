defmodule Treby.AI.Tools.UpdateCustomField do
  @moduledoc "Destructive tool: update a custom field (admin)."

  alias Treby.AI.Tools

  @fields ~w(name field_type applies_to options required position)

  def name, do: "update_custom_field"

  def description, do: "Update a custom field's name, type, options or position."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "field_id" => %{"type" => "string"},
        "name" => %{"type" => "string"},
        "field_type" => %{"type" => "string"},
        "applies_to" => %{"type" => "string"},
        "options" => %{"type" => "array", "items" => %{"type" => "string"}},
        "required" => %{"type" => "boolean"},
        "position" => %{"type" => "integer"}
      },
      "required" => ["field_id"]
    }
  end

  def summary(args) do
    %{
      title: "Update custom field",
      fields: [
        {"Field", args["field_id"]},
        {"Name", args["name"]},
        {"Type", args["field_type"]},
        {"Applies to", args["applies_to"]},
        {"Required", args["required"]},
        {"Position", args["position"]},
        {"Options", args["options"]}
      ]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      field = Treby.Customization.get_custom_field!(ctx[:tenant_id], args["field_id"])

      case Treby.Customization.update_custom_field(
             field,
             Map.take(args, @fields),
             Tools.actor(ctx)
           ) do
        {:ok, updated} -> {:ok, %{"id" => updated.id}}
        {:error, reason} -> {:error, Tools.format_errors(reason)}
      end
    end
  rescue
    Ecto.NoResultsError -> {:error, "custom field not found"}
  end
end
