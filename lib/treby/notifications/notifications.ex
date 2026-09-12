defmodule Treby.Notifications do
  @moduledoc """
  The Notifications context — manages notification preferences and dispatches
  automated emails for pipeline events and application submissions.
  """

  import Ecto.Query, warn: false
  alias Treby.Notifications.Email, as: NotificationEmail
  alias Treby.Notifications.Inbox
  alias Treby.Repo
  alias Treby.Tenants.Tenant

  @default_preferences %{
    "stage_change_candidate" => true,
    "new_application_candidate" => true,
    "new_application_team" => true,
    "interview_reminder" => true
  }

  @allowed_retention [7, 14, 30, 60, 90]
  @default_retention 30

  defp normalize_pref_value(v) when is_boolean(v), do: %{"email" => v, "inbox" => true}

  defp normalize_pref_value(%{"email" => _, "inbox" => _} = m),
    do: %{"email" => !!m["email"], "inbox" => !!m["inbox"]}

  defp normalize_pref_value(%{email: e, inbox: i}), do: %{"email" => !!e, "inbox" => !!i}
  defp normalize_pref_value(_), do: %{"email" => true, "inbox" => true}

  @doc """
  Returns the notification preferences for a tenant, normalized to %{"email"=>bool,"inbox"=>bool} per type.
  Falls back to defaults for any missing keys. Legacy booleans are migrated on read.
  """
  def notification_preferences(%Tenant{} = tenant) do
    stored = get_in(tenant.settings, ["notifications"]) || %{}

    @default_preferences
    |> Map.merge(stored)
    |> Map.new(fn {k, v} -> {k, normalize_pref_value(v)} end)
  end

  def notification_preferences_enabled?(%Tenant{} = tenant, key) do
    prefs = notification_preferences(tenant)

    case Map.get(prefs, key) do
      %{"email" => v} -> v
      v when is_boolean(v) -> v
      nil -> true
      _ -> true
    end
  end

  def email_enabled?(%Tenant{} = tenant, key) do
    prefs = notification_preferences(tenant)

    case Map.get(prefs, key) do
      %{"email" => v} -> !!v
      v when is_boolean(v) -> !!v
      nil -> true
      _ -> true
    end
  end

  def inbox_enabled?(%Tenant{} = tenant, key) do
    prefs = notification_preferences(tenant)

    case Map.get(prefs, key) do
      %{"inbox" => v} -> !!v
      v when is_boolean(v) -> true
      nil -> true
      _ -> true
    end
  end

  def candidate_notification_enabled?(candidate, key) do
    Treby.CandidatePortal.notification_enabled?(candidate, key)
  end

  def set_notification_preference(%Tenant{} = tenant, key, value) when is_boolean(value) do
    normalized = normalize_pref_value(value)
    notifications = Map.put(notification_preferences(tenant), key, normalized)
    settings = Map.put(tenant.settings || %{}, "notifications", notifications)
    tenant |> Tenant.changeset(%{settings: settings}) |> Repo.update()
  end

  def set_notification_preference(%Tenant{} = tenant, key, %{"email" => _, "inbox" => _} = value) do
    normalized = normalize_pref_value(value)
    notifications = Map.put(notification_preferences(tenant), key, normalized)
    settings = Map.put(tenant.settings || %{}, "notifications", notifications)
    tenant |> Tenant.changeset(%{settings: settings}) |> Repo.update()
  end

  def set_notification_preference(%Tenant{} = tenant, key, %{email: _, inbox: _} = value) do
    set_notification_preference(tenant, key, %{"email" => value.email, "inbox" => value.inbox})
  end

  @doc """
  Flips a notification preference, reloading the tenant first so rapid
  successive toggles never compare against stale settings.
  When channel is nil, flips email (legacy). When :email or :inbox, flips that channel only.
  Returns `{:ok, tenant, new_value}`.
  """
  def toggle_notification_preference(tenant_id, key, channel \\ nil) do
    tenant = Repo.get!(Tenant, tenant_id)
    prefs = notification_preferences(tenant)
    current = Map.get(prefs, key, %{"email" => true, "inbox" => true})
    current = normalize_pref_value(current)

    new_prefs =
      case channel do
        "inbox" -> Map.put(current, "inbox", !current["inbox"])
        "email" -> Map.put(current, "email", !current["email"])
        :inbox -> Map.put(current, "inbox", !current["inbox"])
        :email -> Map.put(current, "email", !current["email"])
        _ -> %{"email" => !current["email"], "inbox" => current["inbox"]}
      end

    case set_notification_preference(tenant, key, new_prefs) do
      {:ok, updated} -> {:ok, updated, new_prefs}
      error -> error
    end
  end

  def get_retention_days(%Tenant{} = tenant) do
    val = get_in(tenant.settings, ["notifications_retention_days"])
    if val in @allowed_retention, do: val, else: @default_retention
  end

  def set_retention_days(%Tenant{} = tenant, days) when is_integer(days) do
    if days in @allowed_retention do
      settings = Map.put(tenant.settings || %{}, "notifications_retention_days", days)
      tenant |> Tenant.changeset(%{settings: settings}) |> Repo.update()
    else
      {:error,
       Ecto.Changeset.add_error(
         %Ecto.Changeset{data: tenant},
         :notifications_retention_days,
         "is invalid"
       )}
    end
  end

  def set_retention_days(%Tenant{} = tenant, days) when is_binary(days) do
    case Integer.parse(days) do
      {int, ""} -> set_retention_days(tenant, int)
      _ -> {:error, :invalid}
    end
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

    unless email_enabled?(tenant, "stage_change_candidate") do
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

    unless email_enabled?(tenant, "new_application_candidate") do
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
  Also fans out to inbox if enabled.
  """
  def notify_team_new_application(application, actor_id \\ nil) do
    application = Repo.preload(application, [:candidate, :job])
    candidate = application.candidate
    job = application.job

    tenant = Repo.get!(Tenant, application.tenant_id)

    if email_enabled?(tenant, "new_application_team") do
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
    end

    if inbox_enabled?(tenant, "new_application") || inbox_enabled?(tenant, "new_application_team") do
      Inbox.create_for_tenant(
        tenant.id,
        %{
          type: "new_application",
          title: "New application: #{candidate.name || candidate.email} — #{job.title}",
          body: "#{candidate.name || candidate.email} applied for #{job.title}",
          link: "/app/candidates/#{candidate.id}"
        },
        actor_id
      )
    end

    :ok
  end

  def notify_inbox(tenant_id, type, attrs, actor_id \\ nil) do
    tenant = Repo.get!(Tenant, tenant_id)

    if inbox_enabled?(tenant, type) do
      Inbox.create_for_tenant(
        tenant_id,
        Map.put(attrs, :type, type),
        actor_id
      )
    else
      {:ok, []}
    end
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
