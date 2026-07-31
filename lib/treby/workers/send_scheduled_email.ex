defmodule Treby.Workers.SendScheduledEmail do
  use Oban.Worker,
    queue: :email,
    max_attempts: 5

  alias Treby.EmailQueue
  alias Treby.EmailQueue.ScheduledEmail
  alias Treby.Repo

  @backoff_by_attempt %{2 => 60, 3 => 240, 4 => 900, 5 => 3600}

  @impl Oban.Worker
  def perform(%Oban.Job{
        attempt: attempt,
        max_attempts: max_attempts,
        args: %{"scheduled_email_id" => id}
      }) do
    scheduled_email = Repo.get(ScheduledEmail, id)

    case scheduled_email do
      nil ->
        {:discard, "scheduled_email not found"}

      %{status: "scheduled"} ->
        do_send(scheduled_email, attempt, max_attempts)

      %{status: status} ->
        {:discard, "email already #{status} (not sending)"}
    end
  end

  @impl Oban.Worker
  def backoff(%Oban.Job{attempt: attempt}) do
    Map.get(@backoff_by_attempt, attempt, 3600)
  end

  defp do_send(scheduled_email, attempt, max_attempts) do
    email =
      Swoosh.Email.new()
      |> Swoosh.Email.to(scheduled_email.to_address)
      |> Swoosh.Email.from(scheduled_email.from_address)
      |> Swoosh.Email.subject(scheduled_email.subject)
      |> maybe_text_body(scheduled_email.body)
      |> maybe_html_body(scheduled_email.html_body)

    case Treby.Mailer.deliver(email) do
      {:ok, _result} ->
        EmailQueue.update_status(scheduled_email, "sent")

      {:error, reason} ->
        reason_str = inspect(reason)
        EmailQueue.record_failure(scheduled_email, reason_str, attempt >= max_attempts)
        {:error, reason}
    end
  end

  defp maybe_text_body(email, nil), do: email
  defp maybe_text_body(email, body), do: Swoosh.Email.text_body(email, body)

  defp maybe_html_body(email, nil), do: email
  defp maybe_html_body(email, html_body), do: Swoosh.Email.html_body(email, html_body)
end
