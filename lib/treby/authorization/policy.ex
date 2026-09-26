defmodule Treby.Authorization.Policy do
  @moduledoc """
  Single policy check for UI and AI agent.

  Accepts an actor map (`%{permissions: MapSet}`), a raw `%MapSet{}`, or nil.
  Returns boolean, never raises. Fail-closed on nil, unknown role/action.
  """

  alias Treby.Authorization

  @doc "True when the actor/effective set allows the action."
  def can?(nil, _action), do: false
  def can?(_, nil), do: false
  def can?(_, ""), do: false

  def can?(%MapSet{} = effective, action) when is_atom(action) do
    Authorization.can?(effective, action)
  rescue
    _ -> false
  end

  def can?(%MapSet{} = effective, action) when is_binary(action) do
    can?(effective, to_action(action))
  end

  def can?(%{permissions: %MapSet{} = effective}, action) do
    can?(effective, action)
  end

  def can?(%{permissions: _}, _action), do: false

  def can?(%{} = actor, action) do
    role = Map.get(actor, :role) || Map.get(actor, "role")
    tenant_id = Map.get(actor, :tenant_id) || Map.get(actor, "tenant_id")

    cond do
      is_nil(role) or role == "" -> false
      is_nil(tenant_id) -> false
      true -> can?(effective_for(tenant_id, role), action)
    end
  end

  def can?(_, _), do: false

  defp effective_for(tenant_id, role) do
    Authorization.effective_for(tenant_id, role)
  rescue
    _ -> MapSet.new()
  end

  defp to_action(action) do
    String.to_existing_atom(action)
  rescue
    _ -> :__unknown_action__
  end
end
