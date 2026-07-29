defmodule TrebyWeb.CandidatesLive.IndexTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions

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

  describe "show page - compose email" do
    test "shows compose email button", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Treby.Candidates.Candidate.changeset(%{
          name: "Email Test",
          email: "emailtest@example.com"
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/#{candidate.id}")

      assert has_element?(view, "button", "Compose Email")
    end

    test "shows compose form when clicking compose", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Treby.Candidates.Candidate.changeset(%{
          name: "Compose Test",
          email: "compose@example.com"
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/#{candidate.id}")

      view
      |> element("button", "+ Compose Email")
      |> render_click()

      assert has_element?(view, "input[name=\"compose[subject]\"]")
      assert has_element?(view, "button", "Send Email")
    end

    test "hides compose form on cancel", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Treby.Candidates.Candidate.changeset(%{
          name: "Cancel Test",
          email: "cancel@example.com"
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/#{candidate.id}")

      view
      |> element("button", "+ Compose Email")
      |> render_click()

      assert has_element?(view, "button", "Send Email")

      view
      |> element("button", "Cancel")
      |> render_click()

      refute has_element?(view, "button", "Send Email")
    end

    test "shows error when sending with empty subject", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Treby.Candidates.Candidate.changeset(%{
          name: "Subject Test",
          email: "subject@example.com"
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/#{candidate.id}")

      view
      |> element("button", "+ Compose Email")
      |> render_click()

      view
      |> form("#compose-form", %{
        "compose" => %{
          "subject" => "",
          "body" => "Hello"
        }
      })
      |> render_submit()

      assert render(view) =~ "Subject is required"
    end

    test "shows error when sending with empty body", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Treby.Candidates.Candidate.changeset(%{
          name: "Body Test",
          email: "body@example.com"
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/#{candidate.id}")

      view
      |> element("button", "+ Compose Email")
      |> render_click()

      view
      |> form("#compose-form", %{
        "compose" => %{
          "subject" => "Hello",
          "body" => ""
        }
      })
      |> render_submit()

      assert render(view) =~ "Message body is required"
    end

    test "sends email successfully", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Treby.Candidates.Candidate.changeset(%{
          name: "Send Test",
          email: "send@example.com"
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/#{candidate.id}")

      view
      |> element("button", "+ Compose Email")
      |> render_click()

      view
      |> form("#compose-form", %{
        "compose" => %{
          "subject" => "Hello from Treby",
          "body" => "This is a test email"
        }
      })
      |> render_submit()

      assert render(view) =~ "Email sent"
      assert_email_sent(subject: "Hello from Treby", to: [{"", "send@example.com"}])
    end
  end
end
