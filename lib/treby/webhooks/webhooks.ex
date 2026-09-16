defmodule Treby.Webhooks do
  @moduledoc """
  Context for outbound webhook subscriptions.

  Webhooks fan out from the existing audit log: `Treby.Audit.log_event/4` and
  `log_event_multi/4` call `dispatch/1`, which enqueues a `WebhookDelivery` Oban
  job when the tenant has active subscriptions matching the event.
  """

  import Ecto.Query, warn: false
  require Logger
  alias Ecto.UUID
  alias Treby.Repo
  alias Treby.Webhooks.{WebhookSubscription, WebhookDeliveryLog}
  alias Treby.Workers.WebhookDelivery

  @doc false
  def list_subscriptions(tenant_id) do
    WebhookSubscription
    |> where([s], s.tenant_id == ^tenant_id)
    |> order_by([s], desc: s.inserted_at)
    |> Repo.all()
  end

  @doc false
  def get_subscription(tenant_id, id) do
    WebhookSubscription
    |> Repo.get_by(tenant_id: tenant_id, id: id)
  end

  @doc false
  def create_subscription(tenant_id, attrs) do
    secret = Map.get(attrs, :secret) || generate_secret()

    %WebhookSubscription{tenant_id: tenant_id}
    |> WebhookSubscription.changeset(Map.put(attrs, :secret, secret))
  end

  @doc false
  def update_subscription(%WebhookSubscription{} = subscription, attrs) do
    attrs = if Map.get(attrs, :secret) in [nil, ""], do: Map.delete(attrs, :secret), else: attrs

    subscription
    |> WebhookSubscription.changeset(attrs)
  end

  @doc false
  def save_subscription(changeset) do
    Repo.insert_or_update(changeset)
  end

  @doc false
  def delete_subscription(%WebhookSubscription{} = subscription) do
    Repo.delete(subscription)
  end

  @doc false
  def active_for_tenant?(tenant_id) do
    WebhookSubscription
    |> where([s], s.tenant_id == ^tenant_id and s.active == true)
    |> Repo.exists?()
  end

  @doc false
  def matching_subscriptions(tenant_id, action) do
    WebhookSubscription
    |> where([s], s.tenant_id == ^tenant_id and s.active == true)
    |> Repo.all()
    |> Enum.filter(&event_matches?(&1, action))
  end

  defp event_matches?(%WebhookSubscription{events: events}, action) do
    Enum.any?(events, &matches_pattern?(&1, action))
  end

  defp matches_pattern?(pattern, action) do
    pattern == "*" or pattern == action or
      (String.ends_with?(pattern, ".*") and
         String.starts_with?(action, String.trim_trailing(pattern, ".*") <> "."))
  end

  @doc """
  Fan out an audit event to webhook subscriptions.

  No-op when the tenant has no active subscriptions. Best-effort: any failure
  enqueuing is logged and never propagates to the caller.
  """
  def dispatch(%{tenant_id: tenant_id, id: event_id} = _audit_event) do
    if active_for_tenant?(tenant_id) do
      try do
        %{audit_event_id: event_id, tenant_id: tenant_id}
        |> WebhookDelivery.new()
        |> Oban.insert()

        :ok
      rescue
        e -> Logger.warning("Webhook dispatch failed: #{inspect(e)}")
      end
    else
      :ok
    end
  end

  def dispatch(_), do: :ok

  @doc """
  Enqueue webhook dispatch from inside an `Ecto.Multi`, so it commits with the
  same transaction as the audit insert. The run step always succeeds so it never
  rolls back the business mutation.
  """
  def dispatch_multi(multi, name), do: dispatch_multi(multi, name, nil)

  def dispatch_multi(multi, name, audit_event_fn) when is_function(audit_event_fn, 1) do
    Ecto.Multi.run(multi, :"webhook_dispatch_#{name}", fn _repo, %{^name => event} ->
      dispatch(audit_event_fn.(event))
      {:ok, :ok}
    end)
  end

  def dispatch_multi(multi, name, _event) do
    Ecto.Multi.run(multi, :"webhook_dispatch_#{name}", fn _repo, %{^name => event} ->
      dispatch(event)
      {:ok, :ok}
    end)
  end

  @doc false
  def build_envelope(
        %{
          id: _event_id,
          action: action,
          entity_type: entity_type,
          entity_id: entity_id,
          tenant_id: tenant_id,
          actor_type: actor_type,
          actor_id: actor_id,
          metadata: metadata,
          inserted_at: occurred_at
        },
        delivery_id,
        current
      ) do
    %{
      id: delivery_id,
      event: action,
      entity_type: entity_type,
      entity_id: entity_id,
      tenant_id: tenant_id,
      occurred_at: DateTime.to_iso8601(occurred_at),
      actor: %{type: actor_type, id: actor_id},
      data: %{
        current: current,
        before: Map.get(metadata, :before) || Map.get(metadata, "before"),
        after: Map.get(metadata, :after) || Map.get(metadata, "after")
      }
    }
  end

  @doc false
  def sign(secret, body) when is_binary(secret) do
    :crypto.mac(:hmac, :sha256, secret, body)
    |> Base.encode16(case: :lower)
  end

  def sign(secret, body), do: sign(to_string(secret), body)

  @doc false
  def log_delivery(attrs) do
    %WebhookDeliveryLog{}
    |> WebhookDeliveryLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc false
  def list_delivery_logs(subscription_id, limit \\ 20) do
    WebhookDeliveryLog
    |> where([l], l.subscription_id == ^subscription_id)
    |> order_by([l], desc: l.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  defp generate_secret do
    Base.url_encode64(:crypto.strong_rand_bytes(24))
  end

  @doc """
  Deliver a synthetic `ping` event to a URL with a secret, without persisting a
  subscription. Used by the admin UI "Send test" action (pre-save and saved).
  """
  def test_ping(url, secret) when is_binary(url) and is_binary(secret) do
    if String.starts_with?(url, "https://") do
      delivery_id = UUID.generate()

      envelope = %{
        id: delivery_id,
        event: "ping",
        entity_type: nil,
        entity_id: nil,
        tenant_id: nil,
        occurred_at: DateTime.to_iso8601(DateTime.utc_now()),
        actor: %{type: "system", id: nil},
        data: %{current: nil, before: nil, after: nil}
      }

      body = Jason.encode!(envelope)
      signature = sign(secret, body)

      headers = [
        {"content-type", "application/json"},
        {"x-treby-signature", "sha256=" <> signature},
        {"x-treby-event", "ping"},
        {"x-treby-delivery-id", delivery_id}
      ]

      case Req.request(method: :post, url: url, body: body, headers: headers) do
        {:ok, %{status: status}} when status in 200..299 -> {:ok, status}
        {:ok, %{status: status}} -> {:error, "HTTP #{status}"}
        {:error, reason} -> {:error, inspect(reason)}
      end
    else
      {:error, "URL must start with https://"}
    end
  end

  def test_ping(_url, _secret), do: {:error, "invalid url or secret"}
end
