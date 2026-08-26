defmodule Treby.CandidatesTest do
  use Treby.DataCase, async: true

  alias Treby.{Tenants, Candidates, Repo}
  alias Treby.Accounts.User
  alias Treby.Candidates.Candidate

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

    {tenant, user}
  end

  describe "tenant_has_candidates?/1" do
    test "returns false when tenant has no candidates" do
      {tenant, _user} = setup_tenant()
      refute Candidates.tenant_has_candidates?(tenant.id)
    end

    test "returns true when tenant has candidates" do
      {tenant, _user} = setup_tenant()

      {:ok, _candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{
          name: "John Doe",
          email: "john@example.com"
        })
        |> Repo.insert()

      assert Candidates.tenant_has_candidates?(tenant.id)
    end
  end
end
