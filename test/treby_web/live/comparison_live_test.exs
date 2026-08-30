defmodule TrebyWeb.ComparisonLive.IndexTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User
  alias Treby.Candidates.Candidate

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Compare Test Corp",
        slug: "compare-test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "compare-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Compare User",
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

  defp create_candidate(tenant, name, email) do
    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidate.changeset(%{
        name: name,
        email: email,
        phone: "555-0000"
      })
      |> Repo.insert()

    candidate
  end

  defp login_user(conn, user) do
    conn
    |> init_test_session(%{
      "user_id" => user.id,
      "tenant_id" => user.tenant_id
    })
  end

  test "renders comparison table for candidate ids in query params", %{conn: conn} do
    {tenant, user} = setup_tenant()

    alice = create_candidate(tenant, "Alice Comp", "alicecomp@example.com")
    bob = create_candidate(tenant, "Bob Comp", "bobcomp@example.com")

    conn = login_user(conn, user)

    {:ok, view, _html} =
      live(conn, "/app/candidates/compare?ids=#{alice.id},#{bob.id}")

    html = render(view)

    assert html =~ "Alice Comp"
    assert html =~ "Bob Comp"
    assert html =~ "555-0000"
    assert html =~ "← Back to candidates"
  end

  test "shows error state when no candidate ids are provided", %{conn: conn} do
    {_tenant, user} = setup_tenant()
    conn = login_user(conn, user)

    {:ok, view, _html} = live(conn, ~p"/app/candidates/compare")

    html = render(view)
    assert html =~ "Select 2-3 candidates"
    assert html =~ "← Back to candidates"
  end
end
