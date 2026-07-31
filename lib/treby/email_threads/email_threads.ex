defmodule Treby.EmailThreads do
  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.EmailThreads.{EmailThread, EmailMessage}
  alias Treby.EmailQueue

  def list_threads_for_candidate(candidate_id) do
    EmailThread
    |> where([t], t.candidate_id == ^candidate_id)
    |> order_by([t], desc: t.last_message_at)
    |> Repo.all()
    |> Repo.preload(:messages)
  end

  def get_thread!(id) do
    EmailThread
    |> Repo.get!(id)
    |> Repo.preload(messages: [thread: []])
  end

  def create_inbound_email(attrs) do
    candidate_id = attrs[:candidate_id]
    tenant_id = attrs[:tenant_id]
    subject = attrs[:subject]

    thread =
      Repo.get_by(EmailThread,
        candidate_id: candidate_id,
        tenant_id: tenant_id,
        subject: subject
      )

    thread =
      case thread do
        nil ->
          %EmailThread{}
          |> EmailThread.changeset(%{
            subject: subject,
            candidate_id: candidate_id,
            tenant_id: tenant_id,
            last_message_at: DateTime.utc_now()
          })
          |> Repo.insert!()

        existing ->
          existing
      end

    message_attrs = %{
      direction: "inbound",
      from_address: attrs[:from_address],
      to_address: attrs[:to_address] || "",
      body: attrs[:body],
      html_body: attrs[:html_body],
      received_at: DateTime.utc_now(),
      thread_id: thread.id,
      status: "sent"
    }

    message =
      %EmailMessage{}
      |> EmailMessage.changeset(message_attrs)
      |> Repo.insert!()

    thread
    |> EmailThread.changeset(%{last_message_at: DateTime.utc_now()})
    |> Repo.update!()

    {:ok, message}
  end

  def create_outbound_email(attrs) do
    candidate_id = attrs[:candidate_id]
    tenant_id = attrs[:tenant_id]
    subject = attrs[:subject]

    thread = find_or_create_thread(candidate_id, tenant_id, subject)
    candidate = Repo.get!(Treby.Candidates.Candidate, candidate_id)

    if schedule = attrs[:schedule] do
      create_scheduled_outbound(thread, candidate, attrs, schedule)
    else
      send_immediate_outbound(thread, candidate, attrs)
    end
  end

  def send_reply(thread_id, from_address, body, _tenant_id, opts \\ []) do
    thread = get_thread!(thread_id)
    candidate = Repo.get!(Treby.Candidates.Candidate, thread.candidate_id)

    if schedule = opts[:schedule] do
      create_scheduled_reply(thread, candidate, from_address, body, schedule)
    else
      send_immediate_reply(thread, candidate, from_address, body)
    end
  end

  def update_email_message_status(message_id, status) do
    message = Repo.get!(EmailMessage, message_id)
    message |> EmailMessage.changeset(%{status: status}) |> Repo.update!()
  end

  defp find_or_create_thread(candidate_id, tenant_id, subject) do
    case Repo.get_by(EmailThread,
           candidate_id: candidate_id,
           tenant_id: tenant_id,
           subject: subject
         ) do
      nil ->
        %EmailThread{}
        |> EmailThread.changeset(%{
          subject: subject,
          candidate_id: candidate_id,
          tenant_id: tenant_id,
          last_message_at: DateTime.utc_now()
        })
        |> Repo.insert!()

      existing ->
        existing
    end
  end

  defp send_immediate_outbound(thread, candidate, attrs) do
    subject = attrs[:subject]
    body = attrs[:body] || ""

    email =
      Swoosh.Email.new()
      |> Swoosh.Email.to(candidate.email)
      |> Swoosh.Email.from(attrs[:from_address])
      |> Swoosh.Email.subject(subject)
      |> Swoosh.Email.text_body(body)

    case Treby.Mailer.deliver(email) do
      {:ok, _result} ->
        message_attrs = %{
          direction: "outbound",
          from_address: attrs[:from_address],
          to_address: candidate.email,
          subject: subject,
          body: body,
          sent_at: DateTime.utc_now(),
          thread_id: thread.id,
          status: "sent"
        }

        message =
          %EmailMessage{}
          |> EmailMessage.changeset(message_attrs)
          |> Repo.insert!()

        thread
        |> EmailThread.changeset(%{last_message_at: DateTime.utc_now()})
        |> Repo.update!()

        {:ok, message}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp create_scheduled_outbound(thread, candidate, attrs, schedule) do
    subject = attrs[:subject]
    body = attrs[:body] || ""
    scheduled_at = schedule.scheduled_at
    jitter_minutes = schedule[:jitter_minutes] || 0

    message_attrs = %{
      direction: "outbound",
      from_address: attrs[:from_address],
      to_address: candidate.email,
      subject: subject,
      body: body,
      thread_id: thread.id,
      status: "scheduled",
      scheduled_at: scheduled_at
    }

    message =
      %EmailMessage{}
      |> EmailMessage.changeset(message_attrs)
      |> Repo.insert!()

    {:ok, scheduled_email} =
      EmailQueue.create_scheduled_email(%{
        tenant_id: attrs[:tenant_id],
        created_by_id: attrs[:created_by_id],
        scheduled_at: scheduled_at,
        jitter_minutes: jitter_minutes,
        to_address: candidate.email,
        from_address: attrs[:from_address],
        subject: subject,
        body: body,
        email_type: "compose",
        thread_id: thread.id,
        email_message_id: message.id
      })

    message
    |> EmailMessage.changeset(%{scheduled_email_id: scheduled_email.id})
    |> Repo.update!()

    EmailQueue.schedule_delivery!(scheduled_email)

    thread
    |> EmailThread.changeset(%{last_message_at: DateTime.utc_now()})
    |> Repo.update!()

    {:ok, message}
  end

  defp send_immediate_reply(thread, candidate, from_address, body) do
    email =
      Swoosh.Email.new()
      |> Swoosh.Email.to(candidate.email)
      |> Swoosh.Email.from(from_address)
      |> Swoosh.Email.subject(thread.subject)
      |> Swoosh.Email.text_body(body)

    case Treby.Mailer.deliver(email) do
      {:ok, _result} ->
        message_attrs = %{
          direction: "outbound",
          from_address: from_address,
          to_address: candidate.email,
          body: body,
          sent_at: DateTime.utc_now(),
          thread_id: thread.id,
          status: "sent"
        }

        message =
          %EmailMessage{}
          |> EmailMessage.changeset(message_attrs)
          |> Repo.insert!()

        thread
        |> EmailThread.changeset(%{last_message_at: DateTime.utc_now()})
        |> Repo.update!()

        {:ok, message}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp create_scheduled_reply(thread, candidate, from_address, body, schedule) do
    scheduled_at = schedule.scheduled_at
    jitter_minutes = schedule[:jitter_minutes] || 0

    message_attrs = %{
      direction: "outbound",
      from_address: from_address,
      to_address: candidate.email,
      body: body,
      thread_id: thread.id,
      status: "scheduled",
      scheduled_at: scheduled_at
    }

    message =
      %EmailMessage{}
      |> EmailMessage.changeset(message_attrs)
      |> Repo.insert!()

    {:ok, scheduled_email} =
      EmailQueue.create_scheduled_email(%{
        tenant_id: thread.tenant_id,
        scheduled_at: scheduled_at,
        jitter_minutes: jitter_minutes,
        to_address: candidate.email,
        from_address: from_address,
        subject: thread.subject,
        body: body,
        email_type: "reply",
        thread_id: thread.id,
        email_message_id: message.id
      })

    message
    |> EmailMessage.changeset(%{scheduled_email_id: scheduled_email.id})
    |> Repo.update!()

    EmailQueue.schedule_delivery!(scheduled_email)

    thread
    |> EmailThread.changeset(%{last_message_at: DateTime.utc_now()})
    |> Repo.update!()

    {:ok, message}
  end
end
