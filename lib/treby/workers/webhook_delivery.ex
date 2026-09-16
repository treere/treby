defmodule Treby.Workers.WebhookDelivery do
  use Oban.Worker,
    queue: :webhooks,
    max_attempts: 5

  alias Ecto.UUID
  alias Treby.Repo
  alias Treby.Audit.AuditEvent
  alias Treby.Webhooks
  alias Treby.Webhooks.Entities

  @backoff_by_attempt %{2 => 60, 3 => 300, 4 => 900, 5 => 3600}

  @impl Oban.Worker
  def perform(%Oban.Job{args: args, attempt: attempt}) do
    event_id = Map.get(args, "audit_event_id") || Map.get(args, :audit_event_id)
    tenant_id = Map.get(args, "tenant_id") || Map.get(args, :tenant_id)

    case Repo.get(AuditEvent, event_id) do
      nil ->
        {:discard, "audit event #{event_id} not found"}

      event ->
        subscriptions = Webhooks.matching_subscriptions(tenant_id, event.action)

        Enum.each(subscriptions, &deliver(&1, event, attempt))
        :ok
    end
  end

  @impl Oban.Worker
  def backoff(%Oban.Job{attempt: attempt}) do
    Map.get(@backoff_by_attempt, attempt, 3600)
  end

  defp deliver(
         %{target_url: url, secret: secret} = subscription,
         %{action: action} = event,
         attempt
       ) do
    delivery_id = UUID.generate()

    current =
      case Entities.fetch(event.entity_type, event.entity_id) do
        {:ok, map} -> map
        _ -> nil
      end

    envelope = Webhooks.build_envelope(event, delivery_id, current)
    body = Jason.encode!(envelope)
    signature = Webhooks.sign(secret, body)

    headers = [
      {"content-type", "application/json"},
      {"x-treby-signature", "sha256=" <> signature},
      {"x-treby-event", action},
      {"x-treby-delivery-id", delivery_id}
    ]

    case Req.request(method: :post, url: url, body: body, headers: headers) do
      {:ok, %{status: status}} when status in 200..299 ->
        log_delivery(subscription, event, delivery_id, envelope, attempt, "success", "#{status}")

      {:ok, %{status: status}} ->
        log_delivery(subscription, event, delivery_id, envelope, attempt, "failed", "#{status}")
        raise "webhook delivery failed: HTTP #{status}"

      {:error, reason} ->
        log_delivery(
          subscription,
          event,
          delivery_id,
          envelope,
          attempt,
          "error",
          inspect(reason)
        )

        raise "webhook delivery error: #{inspect(reason)}"
    end
  end

  defp log_delivery(
         %{id: subscription_id, tenant_id: tenant_id},
         event,
         delivery_id,
         envelope,
         attempt,
         status,
         response
       ) do
    Webhooks.log_delivery(%{
      id: delivery_id,
      tenant_id: tenant_id,
      subscription_id: subscription_id,
      action: event.action,
      payload: envelope,
      status: status,
      attempts: attempt,
      last_response: String.slice(response, 0, 500)
    })
  end
end
