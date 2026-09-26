defmodule TrebyWeb.Hooks.RequirePermissionTest do
  use Treby.DataCase, async: false

  alias Treby.{Memberships, Tenants}
  alias Treby.Accounts.User
  alias TrebyWeb.Hooks.RequirePermission

  defp setup_pair(role) do
    suffix = System.unique_integer([:positive])

    {:ok, tenant} =
      Tenants.create_tenant(%{name: "Hook #{suffix}", slug: "hook-#{suffix}"})

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "hook-#{suffix}@test.com",
        password: "password123",
        name: "Hook",
        role: "admin"
      })
      |> Treby.Repo.insert()

    {:ok, membership} =
      Memberships.create_membership(%{user_id: user.id, tenant_id: tenant.id, role: role})

    {tenant, user, membership}
  end

  defp socket_for(tenant, user, membership) do
    %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        flash: %{},
        current_user: user,
        current_tenant: tenant,
        current_membership: membership
      }
    }
  end

  test "allowed role continues" do
    {tenant, user, membership} = setup_pair("admin")

    assert {:cont, _} =
             RequirePermission.on_mount(
               %{action: :audit_view},
               %{"tenant_slug" => tenant.slug},
               %{"user_id" => user.id},
               socket_for(tenant, user, membership)
             )
  end

  test "denied role halts with redirect" do
    {tenant, user, membership} = setup_pair("recruiter")

    assert {:halt, halted} =
             RequirePermission.on_mount(
               %{action: :audit_view},
               %{"tenant_slug" => tenant.slug},
               %{"user_id" => user.id},
               socket_for(tenant, user, membership)
             )

    assert halted.redirected
  end
end
