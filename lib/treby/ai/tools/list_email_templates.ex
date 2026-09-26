defmodule Treby.AI.Tools.ListEmailTemplates do
  @moduledoc "Read-only tool: list stage email templates."

  def name, do: "list_email_templates"

  def description, do: "List the message templates of the workspace."

  def destructive?, do: false

  def schema, do: %{"type" => "object", "properties" => %{}}

  def run(_args, ctx) do
    {:ok, Treby.EmailTemplates.list_email_templates(ctx[:tenant_id])}
  end
end
