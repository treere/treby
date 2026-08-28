defmodule Treby.Notifications do
  @moduledoc """
  The Notifications context — manages notification preferences and dispatches
  automated emails for pipeline events and application submissions.
  """

  import Ecto.Query, warn: false
  alias Treby.Notifications.Email, as: NotificationEmail
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

  def candidate_notification_enabled?(candidate, key) do
    Treby.CandidatePortal.notification_enabled?(candidate, key)
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
  def notify_stage_change(application, _actor \\ nil) do
    application = Repo.preload(application, [:candidate, :job, :pipeline_stage])
    candidate = application.candidate
    job = application.job
    stage = application.pipeline_stage

    tenant = Repo.get!(Tenant, application.tenant_id)

    unless notification_preferences_enabled?(tenant, "stage_change_candidate") do
      throw(:skip)
    end

    unless candidate_notification_enabled?(candidate, "status_change") do
      throw(:skip)
    end

    # Create a system message in the conversation
    conversations =
      Treby.CandidatePortal.list_conversations_for_candidate(candidate.id, tenant.id)

    application_conversations =
      Enum.filter(conversations, fn conv ->
        conv.context == "application" && conv.application_id == application.id
      end)

    if application_conversations != [] do
      Enum.each(application_conversations, fn conversation ->
        Treby.CandidatePortal.send_message(%{
          sender_type: "system",
          conversation_id: conversation.id,
          body: "Your application has moved to #{stage.name}.",
          message_type: "status_update",
          metadata: %{"stage_name" => stage.name, "stage_type" => stage.stage_type}
        })
      end)

      email =
        NotificationEmail.notification_ping(
          candidate,
          tenant,
          List.first(application_conversations).id,
          "status_change",
          %{"job_title" => job.title, "stage_name" => stage.name}
        )

      case Treby.Mailer.deliver(email) do
        {:ok, _} ->
          log_email_event(
            "stage_change_candidate",
            candidate.email,
            email.subject,
            "sent",
            tenant.id
          )

        {:error, reason} ->
          log_email_event(
            "stage_change_candidate",
            candidate.email,
            email.subject,
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
    _job = application.job

    tenant = Repo.get!(Tenant, application.tenant_id)

    unless notification_preferences_enabled?(tenant, "new_application_candidate") do
      throw(:skip)
    end

    unless candidate_notification_enabled?(candidate, "new_message") do
      throw(:skip)
    end

    email =
      NotificationEmail.notification_ping(candidate, tenant, nil, "new_application", %{
        "job_title" => application.job.title
      })

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
  Log an in-app activity event when a new application is submitted,
  so tenant admins and the job owner are notified inside the app.
  """
  def notify_team_new_application(application) do
    application = Repo.preload(application, [:candidate, :job])
    candidate = application.candidate
    job = application.job

    tenant = Repo.get!(Tenant, application.tenant_id)

    unless notification_preferences_enabled?(tenant, "new_application_team") do
      throw(:skip)
    end

    Treby.Activities.log_event(
      "new_application",
      "application",
      application.id,
      %{
        tenant_id: tenant.id,
        candidate_name: candidate.name || "",
        candidate_email: candidate.email || "",
        job_title: job.title || ""
      }
    )

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
