defmodule Treby.Audit do
  @moduledoc """
  The Audit context — immutable, tenant-isolated audit trail.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Audit.AuditEvent

  @sensitive_keys ~w(password password_hash token otp secret hashed_password resume_content)a
  @sensitive_strings ~w(password token otp secret)

  @doc """
  Log an audit event.

  Required attrs: `tenant_id`, `action`, `entity_type`, `entity_id`.
  Optional: `actor_id`, `actor_type` (default "user"), `metadata` (map with before/after), `ip`, `user_agent`.
  """
  def log_event(action, entity_type, entity_id, attrs \\ %{}) do
    attrs = normalize_attrs(action, entity_type, entity_id, attrs)

    %AuditEvent{}
    |> AuditEvent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Add an audit insert to an `Ecto.Multi` for atomic mutation+audit.

  Example: `multi |> Audit.log_event_multi(:audit, "job.updated", "job", job.id, %{tenant_id: t.id, actor_id: u.id, metadata: %{before: ..., after: ...}})`
  """
  def log_event_multi(multi, name, action, entity_type, entity_id, attrs) do
    attrs = normalize_attrs(action, entity_type, entity_id, attrs)

    Ecto.Multi.insert(multi, name, AuditEvent.changeset(%AuditEvent{}, attrs))
  end

  defp normalize_attrs(action, entity_type, entity_id, attrs) do
    attrs = Enum.into(attrs, %{})

    %{
      action: action,
      entity_type: entity_type,
      entity_id: entity_id,
      tenant_id: attrs[:tenant_id] || attrs["tenant_id"],
      actor_id: attrs[:actor_id] || attrs["actor_id"],
      actor_type: to_string(attrs[:actor_type] || attrs["actor_type"] || "user"),
      metadata: sanitize_metadata(attrs[:metadata] || attrs["metadata"] || %{}, action),
      ip: attrs[:ip] || attrs["ip"],
      user_agent: attrs[:user_agent] || attrs["user_agent"]
    }
  end

  @doc """
  Sanitize metadata to avoid logging secrets or large blobs.
  Drops sensitive keys, truncates long strings to 500 chars, and ensures before/after are maps.
  """
  def sanitize_metadata(metadata, _action) when is_nil(metadata), do: %{}

  def sanitize_metadata(metadata, _action) when not is_map(metadata),
    do: %{value: inspect(metadata)}

  def sanitize_metadata(metadata, _action) do
    metadata
    |> Enum.reject(fn {k, _v} ->
      key_str = to_string(k) |> String.downcase()

      Enum.any?(@sensitive_strings, &String.contains?(key_str, &1)) or
        (is_atom(k) and k in @sensitive_keys) or
        to_string(k) in Enum.map(@sensitive_keys, &to_string/1)
    end)
    |> Enum.map(fn {k, v} -> {k, sanitize_value(v)} end)
    |> Map.new()
  end

  defp sanitize_value(v) when is_binary(v) and byte_size(v) > 500,
    do: String.slice(v, 0, 500) <> "…[truncated]"

  defp sanitize_value(v) when is_struct(v), do: v

  defp sanitize_value(v) when is_map(v) do
    Map.new(v, fn {k, val} -> {k, sanitize_value(val)} end)
    |> Map.drop(Enum.map(@sensitive_keys, &to_string/1))
  end

  defp sanitize_value(v) when is_list(v), do: Enum.map(v, &sanitize_value/1)
  defp sanitize_value(v), do: v

  @doc """
  Build audit attrs from a Plug conn or LiveView socket assigns current_scope.

  Accepts `%{tenant, user}` or `Treby.Accounts.Scope` etc. Falls back to explicit attrs.
  """
  def attrs_from_scope(scope, extra \\ %{}) do
    base =
      cond do
        is_map(scope) and Map.has_key?(scope, :tenant) and Map.has_key?(scope, :user) ->
          %{tenant_id: scope.tenant && scope.tenant.id, actor_id: scope.user && scope.user.id}

        is_map(scope) and Map.has_key?(scope, :current_tenant) ->
          %{
            tenant_id: scope.current_tenant && scope.current_tenant.id,
            actor_id: scope.current_user && scope.current_user.id
          }

        true ->
          %{}
      end

    Map.merge(base, Enum.into(extra, %{}))
  end

  @doc """
  List audit events for a tenant with filters and pagination.

  Options: :actor_id, :action (prefix), :entity_type, :entity_id, :from, :to, :search, :page, :page_size
  """
  def list_events(tenant_id, opts \\ [])

  def list_events(nil, _opts), do: raise(ArgumentError, "tenant_id is required")

  def list_events(tenant_id, opts) do
    opts = Enum.into(opts, %{})
    page = max(1, opts[:page] || opts["page"] || 1)
    page_size = min(100, max(1, opts[:page_size] || opts["page_size"] || 25))
    offset = (page - 1) * page_size

    query =
      AuditEvent
      |> where([a], a.tenant_id == ^tenant_id)
      |> maybe_filter_actor(opts[:actor_id] || opts["actor_id"])
      |> maybe_filter_action(opts[:action] || opts["action"])
      |> maybe_filter_entity_type(opts[:entity_type] || opts["entity_type"])
      |> maybe_filter_entity_id(opts[:entity_id] || opts["entity_id"])
      |> maybe_filter_from(opts[:from] || opts["from"])
      |> maybe_filter_to(opts[:to] || opts["to"])
      |> maybe_search(opts[:search] || opts["search"])
      |> order_by([a], desc: a.inserted_at)
      |> limit(^page_size)
      |> offset(^offset)
      |> preload([:actor])

    {Repo.all(query), %{page: page, page_size: page_size}}
  end

  defp maybe_filter_actor(q, nil), do: q
  defp maybe_filter_actor(q, ""), do: q
  defp maybe_filter_actor(q, actor_id), do: where(q, [a], a.actor_id == ^actor_id)

  defp maybe_filter_action(q, nil), do: q
  defp maybe_filter_action(q, ""), do: q
  defp maybe_filter_action(q, action), do: where(q, [a], ilike(a.action, ^"#{action}%"))

  defp maybe_filter_entity_type(q, nil), do: q
  defp maybe_filter_entity_type(q, ""), do: q
  defp maybe_filter_entity_type(q, v), do: where(q, [a], a.entity_type == ^v)

  defp maybe_filter_entity_id(q, nil), do: q
  defp maybe_filter_entity_id(q, ""), do: q
  defp maybe_filter_entity_id(q, v), do: where(q, [a], a.entity_id == ^v)

  defp maybe_filter_from(q, nil), do: q
  defp maybe_filter_from(q, ""), do: q
  defp maybe_filter_from(q, from), do: where(q, [a], a.inserted_at >= ^from)

  defp maybe_filter_to(q, nil), do: q
  defp maybe_filter_to(q, ""), do: q
  defp maybe_filter_to(q, to), do: where(q, [a], a.inserted_at <= ^to)

  defp maybe_search(q, nil), do: q
  defp maybe_search(q, ""), do: q

  defp maybe_search(q, s) do
    pattern = "%#{s}%"
    where(q, [a], ilike(a.action, ^pattern) or ilike(a.entity_type, ^pattern))
  end

  @doc """
  Count events for pagination context.
  """
  def count_events(tenant_id, opts \\ []) do
    opts = Enum.into(opts, %{})

    AuditEvent
    |> where([a], a.tenant_id == ^tenant_id)
    |> maybe_filter_actor(opts[:actor_id] || opts["actor_id"])
    |> maybe_filter_action(opts[:action] || opts["action"])
    |> maybe_filter_entity_type(opts[:entity_type] || opts["entity_type"])
    |> maybe_filter_entity_id(opts[:entity_id] || opts["entity_id"])
    |> maybe_filter_from(opts[:from] || opts["from"])
    |> maybe_filter_to(opts[:to] || opts["to"])
    |> maybe_search(opts[:search] || opts["search"])
    |> Repo.aggregate(:count)
  end
end
