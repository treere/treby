defmodule TrebyWeb.Permissions do
  @moduledoc """
  Template-friendly permission checks backed by `Treby.Authorization`.
  Denies on nil membership/tenant (fail-closed).
  """

  def can?(nil, _tenant, _action), do: false
  def can?(_membership, nil, _action), do: false

  def can?(%{role: role}, %{id: tenant_id}, action) when is_atom(action) do
    Treby.Authorization.can?(Treby.Authorization.effective_for(tenant_id, role), action)
  rescue
    _ -> false
  end

  def can?(%{"role" => role}, %{"id" => tenant_id}, action) when is_atom(action) do
    Treby.Authorization.can?(Treby.Authorization.effective_for(tenant_id, role), action)
  rescue
    _ -> false
  end

  def can?(_membership, _tenant, _action), do: false

  @doc """
  Membership-derived actor for domain calls (`%{id, role, permissions}`).
  Falls back to the raw user when no membership is present.
  """
  def actor(%{assigns: assigns}), do: actor(assigns)

  def actor(%{} = assigns) do
    membership = Map.get(assigns, :current_membership)
    tenant = Map.get(assigns, :current_tenant)
    user = Map.get(assigns, :current_user)

    cond do
      membership && tenant ->
        role = Map.get(membership, :role) || Map.get(membership, "role")

        %{
          id: user && Map.get(user, :id),
          role: role,
          permissions: Treby.Authorization.effective_for(tenant.id, role)
        }

      membership ->
        role = Map.get(membership, :role) || Map.get(membership, "role")
        %{id: user && Map.get(user, :id), role: role}

      true ->
        user
    end
  rescue
    _ -> Map.get(assigns, :current_user)
  end
end
