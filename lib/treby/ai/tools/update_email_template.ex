defmodule Treby.AI.Tools.UpdateEmailTemplate do
  @moduledoc "Destructive tool: update a stage email template (admin)."

  alias Treby.AI.Tools

  def name, do: "update_email_template"

  def description, do: "Update the message template bound to a pipeline stage type."

  def destructive?, do: true

  def required_role, do: :admin

  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "stage_type" => %{
          "type" => "string",
          "enum" => ["new", "interview", "offer", "hired", "rejected"]
        },
        "name" => %{"type" => "string"},
        "subject" => %{"type" => "string"},
        "body" => %{"type" => "string"}
      },
      "required" => ["stage_type"]
    }
  end

  def run(args, ctx) do
    with :ok <- Tools.authorize(__MODULE__, ctx) do
      attrs =
        %{"tenant_id" => ctx[:tenant_id], "stage_type" => args["stage_type"]}
        |> maybe_put("name", args["name"])
        |> maybe_put("subject", args["subject"])
        |> maybe_put("body", args["body"])

      case Treby.EmailTemplates.upsert_email_template(attrs, Tools.actor(ctx)) do
        {:ok, template} -> {:ok, %{"id" => template.id}}
        {:error, reason} -> {:error, Tools.format_errors(reason)}
      end
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
