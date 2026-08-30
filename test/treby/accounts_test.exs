defmodule Treby.AccountsTest do
  use Treby.DataCase, async: true

  alias Treby.{Tenants, Accounts, Repo}
  alias Treby.Accounts.User

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Test Corp",
        slug: "test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "test-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Test User",
        role: "admin"
      })
      |> Repo.insert()

    {:ok, _} =
      Treby.Memberships.create_membership(%{
        user_id: user.id,
        tenant_id: tenant.id,
        role: user.role
      })

    {tenant, user}
  end

  describe "has_members_besides?/2" do
    test "returns false when tenant has only the given user" do
      {tenant, user} = setup_tenant()
      refute Accounts.has_members_besides?(tenant.id, user.id)
    end

    test "returns true when tenant has other users" do
      {tenant, user} = setup_tenant()

      {:ok, _member} =
        tenant
        |> Ecto.build_assoc(:users)
        |> User.changeset(%{
          email: "member-#{System.unique_integer([:positive])}@test.com",
          password: "password123",
          name: "Team Member",
          role: "member"
        })
        |> Repo.insert()

      {:ok, _} =
        Treby.Memberships.create_membership(%{
          user_id: _member.id,
          tenant_id: tenant.id,
          role: _member.role
        })

      assert Accounts.has_members_besides?(tenant.id, user.id)
    end
  end
end
