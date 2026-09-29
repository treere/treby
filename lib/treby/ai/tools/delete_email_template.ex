defmodule Treby.AI.Tools.DeleteEmailTemplate do
  @moduledoc "Destructive tool: delete a stage email template (admin)."

  alias Treby.AI.Tools

  def name, do: "delete_email_template"

  def description, do: "Delete a message template of the workspace."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{"template_id" => %{"type" => "string"}},
      "required" => ["template_id"]
    }
  end

  def summary(args) do
    %{
      title: "Delete email template",
      fields: [
        {"Template", args["template_id"]}
      ]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      template = Treby.EmailTemplates.get_email_template!(args["template_id"])

      if template.tenant_id == ctx[:tenant_id] do
        case Treby.EmailTemplates.delete_email_template(template, Tools.actor(ctx)) do
          {:ok, deleted} -> {:ok, %{"id" => deleted.id}}
          {:error, reason} -> {:error, Tools.format_errors(reason)}
        end
      else
        {:error, "template not found"}
      end
    end
  rescue
    Ecto.NoResultsError -> {:error, "template not found"}
  end
end
