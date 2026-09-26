defmodule Treby.Memberships do
  @moduledoc """
  Memberships link a global user identity to a tenant workspace with a role.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Memberships.Membership
  alias Treby.Tenants.Tenant
  alias Treby.Accounts.User

  def get_membership(user_id, tenant_id, opts \\ []) do
    Repo.get_by(Membership, [user_id: user_id, tenant_id: tenant_id], opts)
  end

  def get_membership!(user_id, tenant_id, opts \\ []) do
    Repo.get_by!(Membership, [user_id: user_id, tenant_id: tenant_id], opts)
  end

  def member?(user_id, tenant_id) do
    Repo.exists?(from m in Membership, where: m.user_id == ^user_id and m.tenant_id == ^tenant_id)
  end

  def access_for(user_id, slug) when is_binary(slug) do
    case Treby.Tenants.get_tenant_by_slug(slug) do
      nil ->
        {:error, :no_tenant}

      %Tenant{} = tenant ->
        case get_membership(user_id, tenant.id, tenant_id: tenant.id) do
          nil ->
            {:error, :no_membership}

          membership ->
            {:ok,
             %{
               tenant: tenant,
               membership: membership,
               available: list_tenants_for_user(user_id)
             }}
        end
    end
  end

  def access_for(_user_id, _slug), do: {:error, :no_tenant}

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

  # Workspace switcher: spans the user's tenants by design, so scoping it
  # to a single tenant would be nonsense. Explicit tenant_id opt still honored.
  def list_tenants_for_user(user_id, opts \\ []) do
    from(t in Tenant,
      join: m in Membership,
      on: m.tenant_id == t.id,
      where: m.user_id == ^user_id,
      select: %{tenant: t, membership: m}
    )
    |> Repo.all(Keyword.put_new(opts, :skip_tenant_id, true))
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

  def update_membership(%Membership{} = membership, attrs, actor \\ nil) do
    if actor &&
         not Treby.Authorization.can_actor?(actor, membership.tenant_id, :team_manage) do
      {:error, :unauthorized}
    else
      case membership |> Membership.changeset(attrs) |> Repo.update() do
        {:ok, updated} ->
          Treby.Audit.log_event("membership.updated", "membership", updated.id, %{
            tenant_id: updated.tenant_id,
            actor_id: Treby.Authorization.Actor.id(actor),
            metadata: %{after: %{role: updated.role}}
          })

          {:ok, updated}

        error ->
          error
      end
    end
  end

  def remove_membership(%Membership{} = membership, actor \\ nil) do
    case Repo.delete(membership) do
      {:ok, deleted} ->
        Treby.Audit.log_event("membership.removed", "membership", deleted.id, %{
          tenant_id: deleted.tenant_id,
          actor_id: Treby.Authorization.Actor.id(actor),
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
