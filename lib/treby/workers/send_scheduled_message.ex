defmodule Treby.Workers.SendScheduledMessage do
  use Oban.Worker,
    queue: :messages,
    max_attempts: 5

  @backoff_by_attempt %{2 => 60, 3 => 240, 4 => 900, 5 => 3600}
  @backoff_default 3600

  use Treby.Workers.BaseWorker

  alias Treby.Repo
  alias Treby.ScheduledMessages
  alias Treby.ScheduledMessages.ScheduledMessage

  @impl Oban.Worker
  def perform(%Oban.Job{
        attempt: attempt,
        max_attempts: max_attempts,
        args: %{"scheduled_message_id" => id}
      }) do
    scheduled_message = Repo.get(ScheduledMessage, id, skip_tenant_id: true)
    if scheduled_message, do: Repo.put_tenant_id(scheduled_message.tenant_id)

    case scheduled_message do
      nil ->
        {:discard, "scheduled_message not found"}

      %{status: "scheduled"} ->
        do_send(scheduled_message, attempt, max_attempts)

      %{status: status} ->
        {:discard, "message already #{status} (not sending)"}
    end
  end

  defp do_send(scheduled_message, attempt, max_attempts) do
    case ScheduledMessages.do_deliver(scheduled_message) do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        reason_str = inspect(reason)
        ScheduledMessages.record_failure(scheduled_message, reason_str, attempt >= max_attempts)
        {:error, reason}
    end
  end
end
