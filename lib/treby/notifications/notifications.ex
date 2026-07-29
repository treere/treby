defmodule Treby.Notifications do
  @moduledoc """
  The Notifications context — manages notification preferences and dispatches
  automated emails for pipeline events and application submissions.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Tenants.Tenant

  @default_preferences %{
    "stage_change_candidate" => true,
    "new_application_candidate" => true,
    "new_application_team" => true,
    "interview_reminder" => true
  }

  @doc """
  Returns the notification preferences for a tenant.
  Falls back to defaults for any missing keys.
  """
  def notification_preferences(%Tenant{} = tenant) do
    stored = get_in(tenant.settings, ["notifications"]) || %{}
    Map.merge(@default_preferences, stored)
  end

  def notification_preferences_enabled?(%Tenant{} = tenant, key) do
    prefs = notification_preferences(tenant)
    Map.get(prefs, key, true)
  end

  def set_notification_preference(%Tenant{} = tenant, key, value) when is_boolean(value) do
    notifications = Map.put(notification_preferences(tenant), key, value)

    settings = Map.put(tenant.settings || %{}, "notifications", notifications)

    tenant
    |> Tenant.changeset(%{settings: settings})
    |> Repo.update()
  end

  @doc """
  Notify the candidate when their application moves to a new pipeline stage.
  Resolves the email template for the target stage type, renders it with
  variables, and sends it via Swoosh.
  """
  def notify_stage_change(application, actor \\ nil) do
    application = Repo.preload(application, [:candidate, :job, :pipeline_stage])
    candidate = application.candidate
    job = application.job
    stage = application.pipeline_stage

    tenant = Repo.get!(Tenant, application.tenant_id)

    unless notification_preferences_enabled?(tenant, "stage_change_candidate") do
      throw(:skip)
    end

    template =
      Treby.EmailTemplates.get_email_template_for_stage(tenant.id, stage.stage_type)

    if template do
      assigns = %{
        candidate_name: candidate.name || "",
        job_title: job.title || "",
        company_name: tenant.name || "",
        stage_name: stage.name || "",
        recruiter_name: (actor && actor.name) || ""
      }

      {subject, body} = Treby.EmailTemplates.render_email(template, assigns)

      email =
        Swoosh.Email.new()
        |> Swoosh.Email.to(candidate.email)
        |> Swoosh.Email.from({"Treby", "noreply@treby.app"})
        |> Swoosh.Email.subject(subject)
        |> Swoosh.Email.html_body(body)

      case Treby.Mailer.deliver(email) do
        {:ok, _} ->
          log_email_event("stage_change_candidate", candidate.email, subject, "sent", tenant.id)

        {:error, reason} ->
          log_email_event(
            "stage_change_candidate",
            candidate.email,
            subject,
            "failed",
            tenant.id,
            %{error: inspect(reason)}
          )
      end
    end

    :ok
  catch
    :skip -> :ok
  end

  @doc """
  Send a confirmation email to the candidate after they apply via the career page.
  """
  def notify_new_application_candidate(application) do
    application = Repo.preload(application, [:candidate, :job])
    candidate = application.candidate
    job = application.job

    tenant = Repo.get!(Tenant, application.tenant_id)

    unless notification_preferences_enabled?(tenant, "new_application_candidate") do
      throw(:skip)
    end

    assigns = %{
      candidate_name: candidate.name || "",
      job_title: job.title || "",
      company_name: tenant.name || ""
    }

    email = Treby.Notifications.Email.new_application_confirmation(candidate, job, assigns)

    case Treby.Mailer.deliver(email) do
      {:ok, _} ->
        log_email_event(
          "new_application_candidate",
          candidate.email,
          email.subject,
          "sent",
          tenant.id
        )

      {:error, reason} ->
        log_email_event(
          "new_application_candidate",
          candidate.email,
          email.subject,
          "failed",
          tenant.id,
          %{error: inspect(reason)}
        )
    end

    :ok
  catch
    :skip -> :ok
  end

  @doc """
  Send notification emails to tenant admins and the job owner when a new application
  is submitted (via career page or manual creation).
  """
  def notify_team_new_application(application) do
    application = Repo.preload(application, [:candidate, :job])
    candidate = application.candidate
    job = application.job

    tenant = Repo.get!(Tenant, application.tenant_id)

    unless notification_preferences_enabled?(tenant, "new_application_team") do
      throw(:skip)
    end

    admin_users =
      Treby.Accounts.list_users(tenant.id)
      |> Enum.filter(&(&1.role == "admin"))

    Enum.each(admin_users, fn admin ->
      assigns = %{
        candidate_name: candidate.name || "",
        job_title: job.title || "",
        company_name: tenant.name || "",
        admin_name: admin.name || ""
      }

      email = Treby.Notifications.Email.new_application_team_alert(admin, candidate, job, assigns)

      case Treby.Mailer.deliver(email) do
        {:ok, _} ->
          log_email_event(
            "new_application_team",
            admin.email,
            email.subject,
            "sent",
            tenant.id
          )

        {:error, reason} ->
          log_email_event(
            "new_application_team",
            admin.email,
            email.subject,
            "failed",
            tenant.id,
            %{error: inspect(reason)}
          )
      end
    end)

    :ok
  catch
    :skip -> :ok
  end

  defp log_email_event(email_type, recipient, subject, status, tenant_id, extra \\ %{}) do
    metadata =
      Map.merge(
        %{
          email_type: email_type,
          recipient: recipient,
          subject: subject,
          status: status
        },
        extra
      )

    Treby.Activities.log_event(
      "email_notification",
      "notification",
      Ecto.UUID.generate(),
      Map.put(metadata, :tenant_id, tenant_id)
    )
  end
end
