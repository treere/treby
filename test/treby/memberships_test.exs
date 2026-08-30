defmodule Treby.MembershipsTest do
  use Treby.DataCase, async: true

  alias Treby.{Tenants, Memberships, Repo}
  alias Treby.Accounts.User

  defp create_tenant(name) do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: name,
        slug:
          "#{String.downcase(String.replace(name, " ", "-"))}-#{System.unique_integer([:positive])}"
      })

    tenant
  end

  defp create_user(tenant, email, role \\ "member") do
    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{email: email, password: "password123", name: "Test", role: role})
      |> Repo.insert()

    # Membership is auto-created via Repo hook for legacy, but also ensure
    # via Memberships (idempotent)
    {:ok, _} =
      Memberships.create_membership(%{user_id: user.id, tenant_id: tenant.id, role: role})

    user
  end

  describe "create_membership/1" do
    test "creates a membership" do
      tenant = create_tenant("Acme")
      user = create_user(tenant, "alice-#{System.unique_integer([:positive])}@test.com", "admin")
      # Already created via helper, verify exists
      assert Memberships.member?(user.id, tenant.id)
    end

    test "enforces uniqueness per pair" do
      tenant = create_tenant("Acme2")
      user = create_user(tenant, "bob-#{System.unique_integer([:positive])}@test.com")

      assert {:error, changeset} =
               Memberships.create_membership(%{
                 user_id: user.id,
                 tenant_id: tenant.id,
                 role: "member"
               })

      assert errors_on(changeset).user_id
    end

    test "role per membership" do
      tenant_a = create_tenant("A Corp")
      tenant_b = create_tenant("B Corp")
      email = "multi-#{System.unique_integer([:positive])}@test.com"

      {:ok, user} =
        tenant_a
        |> Ecto.build_assoc(:users)
        |> User.changeset(%{email: email, password: "password123", name: "Multi", role: "member"})
        |> Repo.insert()

      {:ok, _} =
        Memberships.create_membership(%{user_id: user.id, tenant_id: tenant_a.id, role: "member"})

      {:ok, _} =
        Memberships.create_membership(%{user_id: user.id, tenant_id: tenant_b.id, role: "admin"})

      m_a = Memberships.get_membership(user.id, tenant_a.id)
      m_b = Memberships.get_membership(user.id, tenant_b.id)
      assert m_a.role == "member"
      assert m_b.role == "admin"
    end
  end

  describe "member?/2" do
    test "returns true when membership exists" do
      tenant = create_tenant("Check")
      user = create_user(tenant, "check-#{System.unique_integer([:positive])}@test.com")
      assert Memberships.member?(user.id, tenant.id)
    end

    test "returns false when no membership" do
      tenant = create_tenant("Check2")
      other = create_tenant("Other")
      user = create_user(tenant, "nomem-#{System.unique_integer([:positive])}@test.com")
      refute Memberships.member?(user.id, other.id)
    end
  end

  describe "list_tenants_for_user/1 and list_members_for_tenant/1" do
    test "lists correctly" do
      tenant = create_tenant("List")
      user = create_user(tenant, "list-#{System.unique_integer([:positive])}@test.com")
      tenants = Memberships.list_tenants_for_user(user.id)
      assert length(tenants) == 1
      assert hd(tenants).tenant.id == tenant.id

      members = Memberships.list_members_for_tenant(tenant.id)
      assert length(members) == 1
      assert hd(members).user_id == user.id
    end
  end
end
