defmodule Treby.EmailThreads do
  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.EmailThreads.{EmailThread, EmailMessage}

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

    # Find or create thread
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

    # Create the message
    message_attrs = %{
      direction: "inbound",
      from_address: attrs[:from_address],
      to_address: attrs[:to_address] || "",
      body: attrs[:body],
      html_body: attrs[:html_body],
      received_at: DateTime.utc_now(),
      thread_id: thread.id
    }

    message =
      %EmailMessage{}
      |> EmailMessage.changeset(message_attrs)
      |> Repo.insert!()

    # Update thread timestamp
    thread
    |> EmailThread.changeset(%{last_message_at: DateTime.utc_now()})
    |> Repo.update!()

    {:ok, message}
  end

  def create_outbound_email(attrs) do
    candidate_id = attrs[:candidate_id]
    tenant_id = attrs[:tenant_id]
    subject = attrs[:subject]
    body = attrs[:body] || ""

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

    candidate = Repo.get!(Treby.Candidates.Candidate, candidate_id)

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
          thread_id: thread.id
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

  def send_reply(thread_id, from_address, body, _tenant_id) do
    thread = get_thread!(thread_id)

    # Get candidate email
    candidate = Repo.get!(Treby.Candidates.Candidate, thread.candidate_id)

    # Send via Swoosh
    email =
      Swoosh.Email.new()
      |> Swoosh.Email.to(candidate.email)
      |> Swoosh.Email.from(from_address)
      |> Swoosh.Email.subject(thread.subject)
      |> Swoosh.Email.text_body(body)

    case Treby.Mailer.deliver(email) do
      {:ok, _result} ->
        # Create outbound message
        message_attrs = %{
          direction: "outbound",
          from_address: from_address,
          to_address: candidate.email,
          body: body,
          sent_at: DateTime.utc_now(),
          thread_id: thread.id
        }

        message =
          %EmailMessage{}
          |> EmailMessage.changeset(message_attrs)
          |> Repo.insert!()

        # Update thread timestamp
        thread
        |> EmailThread.changeset(%{last_message_at: DateTime.utc_now()})
        |> Repo.update!()

        {:ok, message}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
