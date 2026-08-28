defmodule Treby.ScheduledMessages do
  @moduledoc """
  The ScheduledMessages context — manages scheduled portal messages
  with reliable Oban-based delivery and retry.
  """

  import Ecto.Query, warn: false
  alias Treby.CandidatePortal
  alias Treby.Repo
  alias Treby.ScheduledMessages.ScheduledMessage
  alias Treby.Workers.SendScheduledMessage

  def list_scheduled(tenant_id) do
    ScheduledMessage
    |> where([s], s.tenant_id == ^tenant_id and s.status in ~w(scheduled))
    |> order_by([s], asc: s.send_at)
    |> Repo.all()
  end

  def list_sent(tenant_id) do
    ScheduledMessage
    |> where([s], s.tenant_id == ^tenant_id and s.status == "sent")
    |> order_by([s], desc: s.sent_at)
    |> Repo.all()
  end

  def list_failed(tenant_id) do
    ScheduledMessage
    |> where([s], s.tenant_id == ^tenant_id and s.status == "failed")
    |> order_by([s], desc: s.failed_at)
    |> Repo.all()
  end

  def list_cancelled(tenant_id) do
    ScheduledMessage
    |> where([s], s.tenant_id == ^tenant_id and s.status == "cancelled")
    |> order_by([s], desc: s.updated_at)
    |> Repo.all()
  end

  def get_scheduled_message!(id), do: Repo.get!(ScheduledMessage, id)

  @doc """
  Creates a scheduled message and schedules Oban delivery.
  """
  def create_scheduled_message(attrs) do
    %ScheduledMessage{}
    |> ScheduledMessage.changeset(
      attrs
      |> Map.put(:status, "scheduled")
    )
    |> Repo.insert()
    |> case do
      {:ok, scheduled_message} ->
        schedule_delivery!(scheduled_message)
        {:ok, scheduled_message}

      error ->
        error
    end
  end

  @doc """
  Posts a scheduled message immediately if it is still scheduled.
  """
  def deliver_now(%ScheduledMessage{} = scheduled_message) do
    if scheduled_message.status == "scheduled" do
      do_deliver(scheduled_message)
    else
      {:ok, scheduled_message}
    end
  end

  def cancel(%ScheduledMessage{} = scheduled_message) do
    scheduled_message
    |> ScheduledMessage.changeset(%{status: "cancelled"})
    |> Repo.update()
  end

  def edit(%ScheduledMessage{} = scheduled_message, attrs) do
    update_attrs =
      attrs
      |> Map.put(:send_at, attrs[:send_at] || scheduled_message.send_at)
      |> Map.drop([:tenant_id, :conversation_id, :status, :id])

    scheduled_message
    |> ScheduledMessage.changeset(update_attrs)
    |> Repo.update()
    |> case do
      {:ok, updated} ->
        reschedule_delivery!(updated)
        {:ok, updated}

      error ->
        error
    end
  end

  def force_send(%ScheduledMessage{} = scheduled_message) do
    now = DateTime.utc_now()

    Repo.transaction(fn ->
      scheduled_message
      |> ScheduledMessage.changeset(%{send_at: now, status: "scheduled"})
      |> Repo.update!()

      updated = %{scheduled_message | send_at: now}
      reschedule_delivery!(updated)
      :ok
    end)
  end

  def retry_failed(%ScheduledMessage{} = scheduled_message) do
    now = DateTime.utc_now()

    Repo.transaction(fn ->
      scheduled_message
      |> ScheduledMessage.changeset(%{
        status: "scheduled",
        send_at: now,
        error_reason: nil,
        failed_at: nil,
        retry_count: 0
      })
      |> Repo.update!()

      schedule_delivery!(%{scheduled_message | status: "scheduled", send_at: now})
      :ok
    end)
  end

  def delete(%ScheduledMessage{} = scheduled_message) do
    Repo.delete(scheduled_message)
  end

  @doc """
  Marks a scheduled message as sent after successful delivery.
  """
  def update_status(%ScheduledMessage{} = scheduled_message, "sent") do
    scheduled_message
    |> ScheduledMessage.changeset(%{status: "sent", sent_at: DateTime.utc_now()})
    |> Repo.update()
  end

  def update_status(%ScheduledMessage{} = scheduled_message, status) do
    scheduled_message
    |> ScheduledMessage.changeset(%{status: status})
    |> Repo.update()
  end

  @doc """
  Records a delivery failure, optionally marking the message as failed.
  """
  def record_failure(%ScheduledMessage{} = scheduled_message, error_reason, final?) do
    changes = %{
      error_reason: error_reason,
      retry_count: (scheduled_message.retry_count || 0) + 1,
      status: if(final?, do: "failed", else: "scheduled")
    }

    changes =
      if final? do
        Map.put(changes, :failed_at, DateTime.utc_now())
      else
        changes
      end

    scheduled_message
    |> ScheduledMessage.changeset(changes)
    |> Repo.update()
  end

  def schedule_delivery!(%ScheduledMessage{} = scheduled_message) do
    %{scheduled_message_id: scheduled_message.id}
    |> SendScheduledMessage.new(scheduled_at: scheduled_message.send_at)
    |> Oban.insert!()
  end

  def reschedule_delivery!(%ScheduledMessage{} = scheduled_message) do
    existing_job =
      Oban.Job
      |> where([j], fragment("?->>'scheduled_message_id' = ?", j.args, ^scheduled_message.id))
      |> Repo.one()

    if existing_job do
      Repo.delete!(existing_job)
    end

    schedule_delivery!(scheduled_message)
  end

  @doc """
  Inserts the message into the conversation via CandidatePortal.send_message/1.
  """
  def do_deliver(%ScheduledMessage{} = scheduled_message) do
    attrs = %{
      sender_type: scheduled_message.sender_type,
      sender_id: scheduled_message.sender_id,
      conversation_id: scheduled_message.conversation_id,
      body: scheduled_message.body,
      message_type: scheduled_message.message_type,
      metadata: scheduled_message.metadata || %{}
    }

    case CandidatePortal.send_message(attrs) do
      {:ok, _message} ->
        update_status(scheduled_message, "sent")

      {:error, _changeset} ->
        {:error, :insert_failed}
    end
  end
end
