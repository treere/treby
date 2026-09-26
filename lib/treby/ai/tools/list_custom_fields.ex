defmodule Treby.AI.Tools.ListCustomFields do
  @moduledoc "Read-only tool: list custom fields."

  def name, do: "list_custom_fields"

  def description, do: "List the custom fields configured in the workspace."

  def destructive?, do: false

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "applies_to" => %{
          "type" => "string",
          "description" => "Optional filter (e.g. candidate, job)"
        }
      }
    }
  end

  def run(args, ctx) do
    fields =
      if args["applies_to"] do
        Treby.Customization.list_custom_fields_for(ctx[:tenant_id], args["applies_to"])
      else
        Treby.Customization.list_custom_fields(ctx[:tenant_id])
      end

    {:ok, fields}
  end
end
