defmodule TrebyWeb.Permissions do
  @moduledoc """
  Template-friendly permission checks backed by `Treby.Authorization.Policy`.
  Denies on nil membership/tenant (fail-closed).
  """

  alias Treby.Authorization.{Actor, Policy}

  # Legacy entry-point, delegates to Policy. Use Policy.can?/2 with Actor.from/1 for new code.
  def can?(nil, _tenant, _action), do: false
  def can?(_membership, nil, _action), do: false

  def can?(%{} = membership, %{} = tenant, action) when is_atom(action) do
    membership |> Actor.from(tenant) |> Policy.can?(action)
  rescue
    _ -> false
  end

  def can?(_membership, _tenant, _action), do: false

  @doc """
  Membership-derived actor for domain calls (`%{id, role, permissions}`).
  Falls back to the raw user when no membership is present.
  Legacy entry-point, delegates to Actor. Use Actor.from/1 for new code.
  """
  # Legacy entry-point, delegates to Actor. Use Actor.from/1 for new code.
  def actor(%{assigns: _} = socket), do: Actor.from(socket)

  def actor(%{} = assigns) do
    actor = Actor.from(assigns)

    cond do
      is_nil(actor[:role]) ->
        Map.get(assigns, :current_user)

      Map.get(actor, :permissions) == MapSet.new() and is_nil(actor[:role]) ->
        Map.get(assigns, :current_user)

      true ->
        actor
    end
  rescue
    _ -> Map.get(assigns, :current_user)
  end
end
