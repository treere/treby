defmodule Treby.AI.Tools.CreateEmailTemplate do
  @moduledoc "Destructive tool: create or update a stage email template."

  alias Treby.AI.Tools

  def name, do: "create_email_template"

  def description, do: "Create or update a message template bound to a pipeline stage."

  def destructive?, do: true

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "name" => %{"type" => "string"},
        "stage_type" => %{
          "type" => "string",
          "enum" => ["new", "interview", "offer", "hired", "rejected"]
        },
        "subject" => %{"type" => "string"},
        "body" => %{"type" => "string"}
      },
      "required" => ["name", "stage_type", "subject", "body"]
    }
  end

  def run(args, ctx) do
    attrs = %{
      "tenant_id" => ctx[:tenant_id],
      "name" => args["name"],
      "stage_type" => args["stage_type"],
      "subject" => args["subject"],
      "body" => args["body"]
    }

    case Treby.EmailTemplates.upsert_email_template(attrs, ctx[:user]) do
      {:ok, template} -> {:ok, %{"id" => template.id}}
      {:error, reason} -> {:error, Tools.format_errors(reason)}
    end
  end
end
