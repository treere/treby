defmodule Treby.Authorization.Actor do
  @moduledoc """
  Single normalization point for permission actors.

  Accepts LiveView sockets, assigns maps, agent ctx maps, or membership maps
  and always returns `%{id: _, role: _}` plus `:permissions` when resolvable.
  Fail-closed: nil role denies; membership path without tenant omits permissions
  so checks deny; ctx role without tenant falls back to preset defaults;
  never raises.
  """

  alias Treby.Authorization

  @doc "Build an actor from a socket, assigns, ctx, or membership map."
  def from(%{assigns: assigns}) when is_map(assigns), do: from(assigns)

  def from(%{} = source) do
    cond do
      membership_context?(source) -> from_membership_assigns(source)
      actor_context?(source) -> from_ctx(source)
      membership_shape?(source) -> from_membership_row(source)
      true -> empty(nil)
    end
  end

  def from(_), do: empty(nil)

  @doc "Build an actor from an explicit membership + tenant pair."
  def from(membership, tenant) do
    from(%{current_membership: membership, current_tenant: tenant})
  end

  @doc "Nil-safe actor id: nil actor yields nil, present actor yields its id."
  def id(nil), do: nil
  def id(%{} = actor), do: Map.get(actor, :id) || Map.get(actor, "id")

  defp membership_context?(source) do
    Map.has_key?(source, :current_membership) or Map.has_key?(source, "current_membership") or
      Map.has_key?(source, :membership)
  end

  defp actor_context?(source) do
    Map.has_key?(source, :actor) or Map.has_key?(source, :permissions) or
      Map.has_key?(source, :role) or Map.has_key?(source, "role") or
      Map.has_key?(source, :tenant_id)
  end

  defp membership_shape?(source) do
    (Map.has_key?(source, :role) or Map.has_key?(source, "role")) and
      (Map.has_key?(source, :tenant_id) or Map.has_key?(source, "tenant_id"))
  end

  defp from_membership_assigns(source) do
    membership =
      Map.get(source, :current_membership) || Map.get(source, "current_membership") ||
        Map.get(source, :membership)

    tenant =
      Map.get(source, :current_tenant) || Map.get(source, "current_tenant") ||
        Map.get(source, :tenant)

    user =
      Map.get(source, :current_user) || Map.get(source, "current_user") || Map.get(source, :user)

    role = get(source, membership, :role)
    tenant_id = tenant_id(tenant) || get_id(membership, :tenant_id)
    id = get_id(user, :id) || get_id(membership, :user_id)

    if is_nil(tenant_id) or tenant_id == "" do
      %{id: id, role: role}
    else
      %{id: id, role: role, permissions: resolve(role, tenant_id, source)}
    end
  end

  defp from_ctx(%{permissions: %MapSet{} = perms} = source) do
    role = Map.get(source, :role) || Map.get(source, "role")

    id =
      Map.get(source, :user_id) || Map.get(source, "user_id") ||
        get_id(Map.get(source, :user) || Map.get(source, "user"), :id)

    %{id: id, role: role, permissions: perms}
  end

  defp from_ctx(%{actor: %{permissions: %MapSet{}} = perms} = source) do
    actor = Map.get(source, :actor)
    %{id: get_id(actor, :id), role: get(actor, nil, :role), permissions: perms}
  end

  defp from_ctx(%{actor: actor} = source) when is_map(actor) do
    role = Map.get(actor, :role) || Map.get(actor, "role") || Map.get(source, :role)
    tenant_id = Map.get(source, :tenant_id) || Map.get(source, "tenant_id")
    id = get_id(actor, :id) || Map.get(source, :user_id) || Map.get(source, "user_id")
    %{id: id, role: role, permissions: resolve(role, tenant_id, source)}
  end

  defp from_ctx(source) do
    role = Map.get(source, :role) || Map.get(source, "role")
    tenant_id = Map.get(source, :tenant_id) || Map.get(source, "tenant_id")

    id =
      Map.get(source, :user_id) || Map.get(source, "user_id") ||
        get_id(Map.get(source, :user) || Map.get(source, "user"), :id)

    %{id: id, role: role, permissions: resolve(role, tenant_id, source)}
  end

  defp from_membership_row(membership) do
    role = Map.get(membership, :role) || Map.get(membership, "role")
    tenant_id = Map.get(membership, :tenant_id) || Map.get(membership, "tenant_id")

    id =
      Map.get(membership, :user_id) || Map.get(membership, "user_id") || Map.get(membership, :id) ||
        Map.get(membership, "id")

    %{id: id, role: role, permissions: resolve(role, tenant_id, %{})}
  end

  defp resolve(role, tenant_id, source) do
    overrides =
      (is_map(source) &&
         (Map.get(source, :permission_overrides) || Map.get(source, "permission_overrides"))) ||
        %{}

    cond do
      is_nil(role) or role == "" -> MapSet.new()
      is_nil(tenant_id) or tenant_id == "" -> Authorization.effective_permissions(role, overrides)
      true -> safe_effective_for(tenant_id, role, overrides)
    end
  end

  defp safe_effective_for(tenant_id, role, overrides) do
    if overrides == %{} do
      Authorization.effective_for(tenant_id, role)
    else
      Authorization.effective_permissions(role, overrides)
    end
  rescue
    _ -> Authorization.effective_permissions(role, %{})
  end

  defp empty(id), do: %{id: id, role: nil, permissions: MapSet.new()}

  defp get(primary, fallback, key) do
    str = Atom.to_string(key)

    primary_val =
      if is_map(primary), do: Map.get(primary, key) || Map.get(primary, str), else: nil

    if primary_val != nil,
      do: primary_val,
      else: fallback && (Map.get(fallback, key) || Map.get(fallback, str))
  end

  defp get_id(nil, _), do: nil
  defp get_id(%{} = m, key), do: Map.get(m, key) || Map.get(m, Atom.to_string(key))
  defp get_id(_, _), do: nil

  defp tenant_id(nil), do: nil
  defp tenant_id(%{} = t), do: Map.get(t, :id) || Map.get(t, "id")
  defp tenant_id(id) when is_binary(id) or is_integer(id), do: id
  defp tenant_id(_), do: nil
end
