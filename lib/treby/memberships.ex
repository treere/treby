defmodule Treby.Memberships do
  @moduledoc """
  Memberships link a global user identity to a tenant workspace with a role.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Memberships.Membership
  alias Treby.Tenants.Tenant
  alias Treby.Accounts.User

  def get_membership(user_id, tenant_id) do
    Repo.get_by(Membership, user_id: user_id, tenant_id: tenant_id)
  end

  def get_membership!(user_id, tenant_id) do
    Repo.get_by!(Membership, user_id: user_id, tenant_id: tenant_id)
  end

  def member?(user_id, tenant_id) do
    Repo.exists?(from m in Membership, where: m.user_id == ^user_id and m.tenant_id == ^tenant_id)
  end

  def create_membership(attrs) do
    case %Membership{} |> Membership.changeset(attrs) |> Repo.insert() do
      {:ok, membership} ->
        Treby.Audit.log_event("membership.created", "membership", membership.id, %{
          tenant_id: membership.tenant_id,
          metadata: %{after: %{user_id: membership.user_id, role: membership.role}}
        })

        {:ok, membership}

      error ->
        error
    end
  end

  def list_tenants_for_user(user_id) do
    from(t in Tenant,
      join: m in Membership,
      on: m.tenant_id == t.id,
      where: m.user_id == ^user_id,
      select: %{tenant: t, membership: m}
    )
    |> Repo.all()
    |> Enum.map(fn %{tenant: tenant, membership: m} ->
      %{tenant: tenant, role: m.role, membership: m}
    end)
  end

  def list_members_for_tenant(tenant_id) do
    from(m in Membership,
      where: m.tenant_id == ^tenant_id,
      preload: [:user]
    )
    |> Repo.all()
  end

  def list_users_for_tenant(tenant_id) do
    from(u in User,
      join: m in Membership,
      on: m.user_id == u.id,
      where: m.tenant_id == ^tenant_id
    )
    |> Repo.all()
  end

  def remove_membership(%Membership{} = membership, actor \\ nil) do
    case Repo.delete(membership) do
      {:ok, deleted} ->
        Treby.Audit.log_event("membership.removed", "membership", deleted.id, %{
          tenant_id: deleted.tenant_id,
          actor_id: actor && actor.id,
          metadata: %{before: %{user_id: deleted.user_id, role: deleted.role}}
        })

        {:ok, deleted}

      error ->
        error
    end
  end

  def remove_membership_by_ids(user_id, tenant_id, actor \\ nil) do
    case get_membership(user_id, tenant_id) do
      nil -> {:error, :not_found}
      membership -> remove_membership(membership, actor)
    end
  end
end
