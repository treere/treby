defmodule Treby.EmailTemplates do
  @moduledoc """
  The EmailTemplates context — manages email templates and sending.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.EmailTemplates.EmailTemplate

  def list_email_templates(tenant_id) do
    EmailTemplate
    |> where([et], et.tenant_id == ^tenant_id)
    |> Repo.all()
  end

  def get_email_template!(id), do: Repo.get!(EmailTemplate, id)

  def get_email_template_for_stage(_tenant_id, nil), do: nil

  def get_email_template_for_stage(tenant_id, stage_type) do
    Repo.get_by(EmailTemplate, tenant_id: tenant_id, stage_type: stage_type)
  end

  def upsert_email_template(attrs, actor \\ nil) do
    if actor && actor.role != "admin" do
      {:error, :unauthorized}
    else
      tenant_id = attrs["tenant_id"]
      stage_type = attrs["stage_type"]

      case Repo.get_by(EmailTemplate, tenant_id: tenant_id, stage_type: stage_type) do
        nil ->
          %EmailTemplate{tenant_id: tenant_id}
          |> EmailTemplate.changeset(attrs)
          |> Repo.insert()

        existing ->
          existing
          |> EmailTemplate.changeset(attrs)
          |> Repo.update()
      end
    end
  end

  def delete_email_template(%EmailTemplate{} = email_template, actor \\ nil) do
    if actor && actor.role != "admin" do
      {:error, :unauthorized}
    else
      Repo.delete(email_template)
    end
  end

  def render_email(template, assigns) do
    variables = %{
      "{candidate_name}" => assigns[:candidate_name] || "",
      "{job_title}" => assigns[:job_title] || "",
      "{company_name}" => assigns[:company_name] || "",
      "{stage_name}" => assigns[:stage_name] || "",
      "{recruiter_name}" => assigns[:recruiter_name] || ""
    }

    subject =
      Enum.reduce(variables, template.subject, fn {key, value}, acc ->
        String.replace(acc, key, value)
      end)

    body =
      Enum.reduce(variables, template.body, fn {key, value}, acc ->
        String.replace(acc, key, value)
      end)

    {subject, body}
  end

  def send_stage_email(template, candidate, _job, assigns \\ %{}) do
    rendered = render_email(template, assigns)

    email =
      Swoosh.Email.new()
      |> Swoosh.Email.to(candidate.email)
      |> Swoosh.Email.from(assigns[:company_name] || "Treby")
      |> Swoosh.Email.subject(elem(rendered, 0))
      |> Swoosh.Email.html_body(elem(rendered, 1))

    case Treby.Mailer.deliver(email) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
