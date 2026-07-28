defmodule TrebyWeb.CandidatesLive.IndexTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Candidates Test Corp",
        slug: "candidates-test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "cand-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Cand User",
        role: "admin"
      })
      |> Repo.insert()

    {tenant, user}
  end

  defp login_user(conn, user) do
    conn
    |> init_test_session(%{
      "user_id" => user.id,
      "tenant_id" => user.tenant_id
    })
  end

  describe "empty state" do
    test "shows empty state with CTAs when no candidates exist", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app/candidates")

      html = render(view)
      assert html =~ "No candidates yet"
      assert html =~ "Add a candidate"
      assert html =~ "Import from CSV"
    end

    test "hides empty state when candidates exist", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, _candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Treby.Candidates.Candidate.changeset(%{
          name: "Jane Smith",
          email: "jane@example.com"
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates")

      html = render(view)
      refute html =~ "No candidates yet"
      assert html =~ "Jane Smith"
    end
  end

  describe "form validation" do
    test "shows flash error when creating candidate with empty name", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app/candidates")

      view
      |> element("button", "+ Add Candidate")
      |> render_click()

      html =
        view
        |> form("#candidate-form", %{
          "candidate" => %{
            "name" => "",
            "email" => "test@example.com"
          }
        })
        |> render_submit()

      assert html =~ "Please review the errors below"
    end
  end

  describe "show page - edit validation" do
    test "shows flash error when saving edit with empty name", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Treby.Candidates.Candidate.changeset(%{
          name: "Valid Name",
          email: "valid@example.com"
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/#{candidate.id}")

      view |> element("button", "Edit") |> render_click()

      html =
        view
        |> form("#edit-candidate-form", %{
          "candidate" => %{
            "name" => "",
            "email" => "valid@example.com"
          }
        })
        |> render_submit()

      assert html =~ "Please review the errors below"
    end
  end
end
