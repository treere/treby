defmodule Treby.CareersTest do
  use Treby.DataCase, async: true

  alias Treby.{Tenants, Careers, Repo}
  alias Treby.Accounts.User
  alias Treby.Careers.CareerPage

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

  describe "has_branding?/1" do
    test "returns false when tenant has no career page" do
      {tenant, _user} = setup_tenant()
      refute Careers.has_branding?(tenant.id)
    end

    test "returns true when tenant has career page branding" do
      {tenant, _user} = setup_tenant()

      {:ok, _career_page} =
        tenant
        |> Ecto.build_assoc(:career_pages)
        |> CareerPage.changeset(%{
          title: "Join Us",
          primary_color: "#3b82f6"
        })
        |> Repo.insert()

      assert Careers.has_branding?(tenant.id)
    end
  end
end
