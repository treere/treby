defmodule Treby.EmailQueue do
  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.EmailQueue.ScheduledEmail
  alias Treby.EmailThreads.EmailMessage
  alias Treby.Workers.SendScheduledEmail

  def list_queued(tenant_id) do
    ScheduledEmail
    |> where([s], s.tenant_id == ^tenant_id and s.status in ^~w(scheduled sending))
    |> order_by([s], asc: s.send_at)
    |> Repo.all()
  end

  def list_sent(tenant_id) do
    ScheduledEmail
    |> where([s], s.tenant_id == ^tenant_id and s.status == "sent")
    |> order_by([s], desc: s.sent_at)
    |> Repo.all()
  end

  def list_failed(tenant_id) do
    ScheduledEmail
    |> where([s], s.tenant_id == ^tenant_id and s.status == "failed")
    |> order_by([s], desc: s.failed_at)
    |> Repo.all()
  end

  def list_cancelled(tenant_id) do
    ScheduledEmail
    |> where([s], s.tenant_id == ^tenant_id and s.status == "cancelled")
    |> order_by([s], desc: s.updated_at)
    |> Repo.all()
  end

  def get_scheduled_email!(id), do: Repo.get!(ScheduledEmail, id)

  def create_scheduled_email(attrs) do
    jitter_minutes = attrs[:jitter_minutes] || 0
    scheduled_at = attrs[:scheduled_at]
    send_at = apply_jitter(scheduled_at, jitter_minutes)

    %ScheduledEmail{}
    |> ScheduledEmail.changeset(
      attrs
      |> Map.put(:send_at, send_at)
      |> Map.put(:status, "scheduled")
    )
    |> Repo.insert()
  end

  def cancel_scheduled_email(%ScheduledEmail{} = scheduled_email) do
    Repo.transaction(fn ->
      scheduled_email
      |> ScheduledEmail.changeset(%{status: "cancelled"})
      |> Repo.update!()

      if message_id = scheduled_email.email_message_id do
        update_email_message_status(message_id, "cancelled")
      end

      :ok
    end)
  end

  def edit_scheduled_email(%ScheduledEmail{} = scheduled_email, attrs) do
    jitter_minutes = attrs[:jitter_minutes] || scheduled_email.jitter_minutes || 0
    scheduled_at = attrs[:scheduled_at] || scheduled_email.scheduled_at
    send_at = apply_jitter(scheduled_at, jitter_minutes)

    update_attrs =
      attrs
      |> Map.put(:send_at, send_at)
      |> Map.drop([:tenant_id, :to_address, :from_address, :email_type, :id])

    Repo.transaction(fn ->
      updated =
        scheduled_email
        |> ScheduledEmail.changeset(update_attrs)
        |> Repo.update!()

      if message_id = updated.email_message_id do
        message_updates = %{}

        message_updates =
          if attrs[:subject],
            do: Map.put(message_updates, :subject, attrs[:subject]),
            else: message_updates

        message_updates =
          if attrs[:body],
            do: Map.put(message_updates, :body, attrs[:body]),
            else: message_updates

        if message_updates != %{} do
          Repo.get!(EmailMessage, message_id)
          |> EmailMessage.changeset(message_updates)
          |> Repo.update!()
        end
      end

      reschedule_delivery!(updated)

      updated
    end)
  end

  def force_send(%ScheduledEmail{} = scheduled_email) do
    now = DateTime.utc_now()

    Repo.transaction(fn ->
      scheduled_email
      |> ScheduledEmail.changeset(%{send_at: now, status: "scheduled"})
      |> Repo.update!()

      updated = %{scheduled_email | send_at: now}
      reschedule_delivery!(updated)

      :ok
    end)
  end

  def delete_scheduled_email(%ScheduledEmail{} = scheduled_email) do
    Repo.transaction(fn ->
      if message_id = scheduled_email.email_message_id do
        Repo.delete!(%Treby.EmailThreads.EmailMessage{id: message_id})
      end

      Repo.delete!(scheduled_email)
      :ok
    end)
  end

  def retry_failed(%ScheduledEmail{} = scheduled_email) do
    now = DateTime.utc_now()

    Repo.transaction(fn ->
      scheduled_email
      |> ScheduledEmail.changeset(%{
        status: "scheduled",
        send_at: now,
        error_reason: nil,
        failed_at: nil,
        retry_count: 0
      })
      |> Repo.update!()

      schedule_delivery!(%{scheduled_email | status: "scheduled", send_at: now})

      :ok
    end)
  end

  def record_failure(%ScheduledEmail{} = scheduled_email, error_reason, final?) do
    changes = %{
      error_reason: error_reason,
      retry_count: (scheduled_email.retry_count || 0) + 1,
      status: if(final?, do: "failed", else: "scheduled")
    }

    changes =
      if final? do
        Map.put(changes, :failed_at, DateTime.utc_now())
      else
        changes
      end

    scheduled_email
    |> ScheduledEmail.changeset(changes)
    |> Repo.update()
  end

  def update_status(%ScheduledEmail{} = scheduled_email, status, opts \\ []) do
    changes =
      case status do
        "sent" ->
          %{status: "sent", sent_at: opts[:at] || DateTime.utc_now()}

        "failed" ->
          %{
            status: "failed",
            failed_at: opts[:at] || DateTime.utc_now(),
            error_reason: opts[:error_reason],
            retry_count: (scheduled_email.retry_count || 0) + 1
          }

        _ ->
          %{status: status}
      end

    Repo.transaction(fn ->
      updated = scheduled_email |> ScheduledEmail.changeset(changes) |> Repo.update!()

      if status == "sent" do
        mark_linked_message_sent(updated)
      end

      updated
    end)
  end

  defp mark_linked_message_sent(%ScheduledEmail{email_message_id: nil}), do: :ok

  defp mark_linked_message_sent(%ScheduledEmail{email_message_id: message_id}) do
    Repo.get!(EmailMessage, message_id)
    |> EmailMessage.changeset(%{status: "sent"})
    |> Repo.update!()

    :ok
  end

  def schedule_delivery!(%ScheduledEmail{} = scheduled_email) do
    %{scheduled_email_id: scheduled_email.id}
    |> SendScheduledEmail.new(scheduled_at: scheduled_email.send_at)
    |> Oban.insert!()
  end

  def reschedule_delivery!(%ScheduledEmail{} = scheduled_email) do
    import Ecto.Query

    existing_job =
      Oban.Job
      |> where([j], fragment("?->>'scheduled_email_id' = ?", j.args, ^scheduled_email.id))
      |> Repo.one()

    if existing_job do
      Repo.delete!(existing_job)
    end

    schedule_delivery!(scheduled_email)
  end

  defp update_email_message_status(message_id, status) do
    Repo.get!(EmailMessage, message_id)
    |> EmailMessage.changeset(%{status: status})
    |> Repo.update!()
  end

  defp apply_jitter(scheduled_at, 0), do: scheduled_at

  defp apply_jitter(scheduled_at, jitter_minutes) when jitter_minutes > 0 do
    offset_seconds = :rand.uniform(2 * jitter_minutes * 60) - jitter_minutes * 60
    DateTime.add(scheduled_at, offset_seconds, :second)
  end
end
