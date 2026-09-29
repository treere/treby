defmodule Treby.AI.Tools.CreateCustomField do
  @moduledoc "Destructive tool: create a custom field (admin)."

  alias Treby.AI.Tools

  def name, do: "create_custom_field"

  def description, do: "Create a custom field on candidates or jobs."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "string"},
        "field_type" => %{"type" => "string"},
        "applies_to" => %{"type" => "string"},
        "options" => %{"type" => "array", "items" => %{"type" => "string"}},
        "required" => %{"type" => "boolean"},
        "position" => %{"type" => "integer"}
      },
      "required" => ["name", "applies_to"]
    }
  end

  def summary(args) do
    %{
      title: "Create custom field",
      fields: [
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
      attrs = Map.merge(%{"tenant_id" => ctx[:tenant_id]}, Map.drop(args, ["tenant_id"]))

      case Treby.Customization.create_custom_field(attrs, Tools.actor(ctx)) do
        {:ok, field} -> {:ok, %{"id" => field.id, "name" => field.name}}
        {:error, reason} -> {:error, Tools.format_errors(reason)}
      end
    end
  end
end
