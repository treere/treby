defmodule TrebyWeb.CandidatesLive.ShowTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User
  alias Treby.Candidates.Candidate

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Candidates Show Test Corp",
        slug: "candidates-show-test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "show-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Show User",
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

  defp create_candidate(tenant, name) do
    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidate.changeset(%{
        name: name,
        email:
          "#{String.downcase(name) |> String.replace(" ", "-")}-#{System.unique_integer([:positive])}@example.com"
      })
      |> Repo.insert()

    candidate
  end

  describe "candidate without applications" do
    test "rejecting a candidate without applications shows an error and does not crash", %{
      conn: conn
    } do
      {tenant, user} = setup_tenant()
      candidate = create_candidate(tenant, "No App Candidate")

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/#{candidate.id}")

      view |> render_click("reject_candidate", %{})

      html =
        view
        |> render_submit("submit_rejection", %{
          "reject" => %{"reason" => "other", "feedback" => "not a fit"}
        })

      assert html =~ "This candidate has no applications to reject"
      assert html =~ "No applications yet"
    end

    test "requesting info on a candidate without applications shows an error and does not crash",
         %{
           conn: conn
         } do
      {tenant, user} = setup_tenant()
      candidate = create_candidate(tenant, "No Info Candidate")

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/#{candidate.id}")

      view |> render_click("request_info", %{})

      html =
        view
        |> render_submit("submit_request_info", %{
          "request_info" => %{"template" => "custom", "message" => "Tell us more"}
        })

      assert html =~ "This candidate has no applications to request information for"
      assert html =~ "No applications yet"
    end

    test "sending a new message to a candidate without applications succeeds", %{conn: conn} do
      {tenant, user} = setup_tenant()
      candidate = create_candidate(tenant, "No Msg Candidate")

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/#{candidate.id}")

      view |> render_click("new_portal_message", %{})

      html =
        view
        |> render_submit("send_new_message", %{
          "message" => %{"subject" => "Hello", "body" => "Welcome aboard"}
        })

      assert html =~ "Message sent"
      assert html =~ "Hello"
    end
  end
end
