defmodule Treby.EmailTemplates do
  @moduledoc """
  The EmailTemplates context — manages message templates per pipeline stage
  and posts rendered templated messages into candidate portal conversations.
  """

  import Ecto.Query, warn: false
  alias Treby.CandidatePortal
  alias Treby.Repo
  alias Treby.EmailTemplates.EmailTemplate
  alias Treby.ScheduledMessages

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

  @doc """
  Renders a template and posts it as a message in the candidate's conversation
  for the application. Creates a conversation if none exists.
  """
  def send_stage_message(template, candidate, application, assigns \\ %{}) do
    {_subject, body} = render_email(template, assigns)

    conversation_id = conversation_for_application(candidate, application, assigns)

    attrs = %{
      sender_type: "recruiter",
      conversation_id: conversation_id,
      body: body,
      message_type: "templated",
      metadata: %{
        "template_id" => template.id,
        "stage_name" => assigns[:stage_name] || ""
      }
    }

    case CandidatePortal.send_message(attrs) do
      {:ok, _message} -> :ok
      {:error, _changeset} -> {:error, :insert_failed}
    end
  end

  @doc """
  Schedules a rendered templated message for future delivery into the
  candidate's conversation.
  """
  def send_stage_message_scheduled(template, candidate, application, assigns, schedule) do
    {_subject, body} = render_email(template, assigns)

    conversation_id = conversation_for_application(candidate, application, assigns)
    tenant_id = assigns[:tenant_id]

    ScheduledMessages.create_scheduled_message(%{
      tenant_id: tenant_id,
      sender_type: "recruiter",
      conversation_id: conversation_id,
      body: body,
      message_type: "templated",
      metadata: %{
        "template_id" => template.id,
        "stage_name" => assigns[:stage_name] || ""
      },
      send_at: schedule.scheduled_at,
      created_by_id: assigns[:actor_id]
    })
  end

  defp conversation_for_application(candidate, application, assigns) do
    existing =
      CandidatePortal.list_conversations_for_application(application.id, application.tenant_id)

    case Enum.find(existing, &(&1.context == "application")) do
      nil ->
        {:ok, conversation} =
          CandidatePortal.create_conversation(%{
            candidate_id: candidate.id,
            tenant_id: application.tenant_id,
            application_id: application.id,
            subject: assigns[:job_title] || "Application",
            context: "application"
          })

        conversation.id

      conversation ->
        conversation.id
    end
  end
end
