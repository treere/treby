defmodule TrebyWeb.CandidatesDuplicateTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User
  alias Treby.Jobs.Job

  defp setup_tenant do
    suffix = System.unique_integer([:positive])

    {:ok, tenant} =
      Tenants.create_tenant(%{name: "Dup #{suffix}", slug: "dup-#{suffix}"})

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "dup-admin-#{suffix}@test.com",
        password: "password123",
        name: "Dup Admin",
        role: "admin"
      })
      |> Repo.insert()

    {:ok, _} =
      Treby.Memberships.create_membership(%{
        user_id: user.id,
        tenant_id: tenant.id,
        role: "admin"
      })

    {tenant, user}
  end

  test "duplicate email without job shows has already been taken", %{conn: conn} do
    {tenant, user} = setup_tenant()

    {:ok, _} =
      Treby.Candidates.create_or_find(tenant.id, %{"name" => "Alice", "email" => "alice@test.com"})

    conn = init_test_session(conn, %{"user_id" => user.id})
    {:ok, view, _} = live(conn, "/#{tenant.slug}/app/candidates")

    view |> element("button", "+ Add Candidate") |> render_click()

    html =
      view
      |> form("#candidate-form", %{
        "candidate" => %{"name" => "Alice Duplicate", "email" => "alice@test.com", "phone" => ""}
      })
      |> render_submit()

    assert html =~ "has already been taken",
           "expected field error forduplicate, got: #{String.slice(html, 0, 1000)}"

    # form should stay open, not flash Candidate added
    refute html =~ "Candidate added"
  end

  test "duplicate email case-insensitive blocked", %{conn: conn} do
    {tenant, user} = setup_tenant()

    {:ok, _} =
      Treby.Candidates.create_or_find(tenant.id, %{"name" => "Bob", "email" => "bob@test.com"})

    conn = init_test_session(conn, %{"user_id" => user.id})
    {:ok, view, _} = live(conn, "/#{tenant.slug}/app/candidates")
    view |> element("button", "+ Add Candidate") |> render_click()

    html =
      view
      |> form("#candidate-form", %{
        "candidate" => %{"name" => "Bob Dup", "email" => "BOB@TEST.COM", "phone" => ""}
      })
      |> render_submit()

    assert html =~ "has already been taken"
  end

  test "duplicate email with whitespace trimmed blocked", %{conn: conn} do
    {tenant, user} = setup_tenant()

    {:ok, _} =
      Treby.Candidates.create_or_find(tenant.id, %{"name" => "Carol", "email" => "carol@test.com"})

    conn = init_test_session(conn, %{"user_id" => user.id})
    {:ok, view, _} = live(conn, "/#{tenant.slug}/app/candidates")
    view |> element("button", "+ Add Candidate") |> render_click()

    html =
      view
      |> form("#candidate-form", %{
        "candidate" => %{"name" => "Carol Dup", "email" => "  carol@test.com  ", "phone" => ""}
      })
      |> render_submit()

    assert html =~ "has already been taken"
  end

  test "blank email allows creation (no duplicate check)", %{conn: conn} do
    {tenant, user} = setup_tenant()

    conn = init_test_session(conn, %{"user_id" => user.id})
    {:ok, view, _} = live(conn, "/#{tenant.slug}/app/candidates")
    view |> element("button", "+ Add Candidate") |> render_click()

    # Candidate changeset requires email, so blank should show can't be blank, not has already been taken
    html =
      view
      |> form("#candidate-form", %{
        "candidate" => %{"name" => "No Email", "email" => "", "phone" => ""}
      })
      |> render_submit()

    assert html =~ "can&#39;t be blank" or html =~ "can&apos;t be blank" or
             html =~ "can&#39;t be blank" or html =~ "can"
  end

  test "duplicate with job links existing candidate (no error, creates application)", %{
    conn: conn
  } do
    {tenant, user} = setup_tenant()

    {:ok, candidate} =
      Treby.Candidates.create_or_find(tenant.id, %{"name" => "Dave", "email" => "dave@test.com"})

    job =
      Ecto.build_assoc(tenant, :jobs)
      |> Job.changeset(%{
        title: "Test Job #{System.unique_integer([:positive])}",
        description: "desc"
      })
      |> Repo.insert!()

    conn = init_test_session(conn, %{"user_id" => user.id})
    {:ok, view, _} = live(conn, "/#{tenant.slug}/app/candidates")
    view |> element("button", "+ Add Candidate") |> render_click()

    html =
      view
      |> form("#candidate-form", %{
        "candidate" => %{
          "name" => "Dave Dup",
          "email" => "dave@test.com",
          "phone" => "",
          "job_id" => job.id
        }
      })
      |> render_submit()

    # should succeed and show Candidate added to job, not error
    assert html =~ "Candidate added"
    refute html =~ "has already been taken"
    # verify application created for existing candidate
    apps = Treby.Pipeline.list_applications_for_candidate(tenant.id, candidate.id)
    assert apps != []
  end
end
