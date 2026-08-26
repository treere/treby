defmodule TrebyWeb.CandidatesMergeLiveTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo, Candidates, Pipeline}
  alias Treby.Accounts.User
  alias Treby.Candidates.{Candidate, DismissedMergeGroup}
  alias Treby.Pipeline.PipelineStage
  alias Treby.Jobs.Job

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Merge Test Corp",
        slug: "merge-test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "merge-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Merge User",
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

  defp create_candidate(tenant, name, email, phone \\ nil) do
    attrs = %{name: name, email: email}
    attrs = if phone, do: Map.put(attrs, :phone, phone), else: attrs

    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidate.changeset(attrs)
      |> Repo.insert()

    candidate
  end

  defp create_application(tenant, job, stage, candidate) do
    {:ok, application} =
      Pipeline.create_application(%{
        tenant_id: tenant.id,
        job_id: job.id,
        candidate_id: candidate.id,
        pipeline_stage_id: stage.id,
        applied_at: DateTime.utc_now()
      })

    application
  end

  defp create_job_and_stage(tenant) do
    pipeline_id = Pipeline.default_pipeline_id(tenant.id)
    pipeline = Repo.get!(Pipeline.Pipeline, pipeline_id)

    {:ok, job} =
      tenant
      |> Ecto.build_assoc(:jobs)
      |> Job.changeset(%{
        title: "Engineer #{System.unique_integer([:positive])}",
        description: "Build things",
        pipeline_id: pipeline_id
      })
      |> Repo.insert()

    {:ok, stage} =
      pipeline
      |> Ecto.build_assoc(:pipeline_stages)
      |> PipelineStage.changeset(%{
        name: "Applied",
        position: 0,
        stage_type: "applied"
      })
      |> Repo.insert()

    {job, stage}
  end

  describe "merge center" do
    test "lists duplicate groups with confidence badges", %{conn: conn} do
      {tenant, user} = setup_tenant()
      _c1 = create_candidate(tenant, "First Person", "first@example.com", "555-0101")
      _c2 = create_candidate(tenant, "First Person", "second@example.com", "555-0101")

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/merge")

      assert render(view) =~ "2 profiles may be the same person"
      assert render(view) =~ "High confidence"
      assert render(view) =~ "Phone + name match"
      assert has_element?(view, "button", "Merge 2 into primary")
    end

    test "dismisses a group suggestion", %{conn: conn} do
      {tenant, user} = setup_tenant()
      _c1 = create_candidate(tenant, "First Person", "first@example.com", "555-0101")
      _c2 = create_candidate(tenant, "First Person", "second@example.com", "555-0101")

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/merge")

      view |> element("button", "Dismiss") |> render_click()

      assert render(view) =~ "No duplicate candidates"
      assert render(view) =~ "Suggestion dismissed"
    end

    test "dismissal persists across page reloads", %{conn: conn} do
      {tenant, user} = setup_tenant()
      _c1 = create_candidate(tenant, "First Person", "first@example.com", "555-0101")
      _c2 = create_candidate(tenant, "First Person", "second@example.com", "555-0101")

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/merge")

      view |> element("button", "Dismiss") |> render_click()
      assert render(view) =~ "No duplicate candidates"

      assert Repo.aggregate(DismissedMergeGroup, :count) == 1

      conn2 = login_user(conn, user)
      {:ok, _view2, html2} = live(conn2, ~p"/app/candidates/merge")
      assert html2 =~ "No duplicate candidates"
    end

    test "merges a group into the selected primary", %{conn: conn} do
      {tenant, user} = setup_tenant()
      primary = create_candidate(tenant, "Keep Me", "keep@example.com", "555-0101")
      absorbed = create_candidate(tenant, "Keep Me", "absorb@example.com", "555-0101")
      {job, stage} = create_job_and_stage(tenant)
      app = create_application(tenant, job, stage, absorbed)

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/merge")

      view
      |> element(~s{input[phx-value-candidate_id="#{primary.id}"]})
      |> render_click()

      view |> element("button", "Merge 2 into primary") |> render_click()

      assert render(view) =~ "Merged 2 profiles into Keep Me"
      assert render(view) =~ "No duplicate candidates"

      assert Repo.get!(Candidate, absorbed.id).merged_into_id == primary.id
      assert Repo.get!(Pipeline.Application, app.id).candidate_id == primary.id
    end
  end

  describe "candidates index" do
    test "shows duplicates badge with count and links to the merge center", %{conn: conn} do
      {tenant, user} = setup_tenant()
      _c1 = create_candidate(tenant, "First Person", "first@example.com", "555-0101")
      _c2 = create_candidate(tenant, "First Person", "second@example.com", "555-0101")

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates")

      assert has_element?(view, ~s{a[href="/app/candidates/merge"]}, "Duplicates")
      assert render(view) =~ ~r/rounded-full px-1\.5 py-0\.5">\s*1\s*<\/span>/
    end

    test "dismissed groups are excluded from the duplicates badge", %{conn: conn} do
      {tenant, user} = setup_tenant()
      _c1 = create_candidate(tenant, "First Person", "first@example.com", "555-0101")
      _c2 = create_candidate(tenant, "First Person", "second@example.com", "555-0101")

      conn = login_user(conn, user)
      {:ok, merge_view, _html} = live(conn, ~p"/app/candidates/merge")
      merge_view |> element("button", "Dismiss") |> render_click()

      conn = login_user(conn, user)
      {:ok, index_view, html} = live(conn, ~p"/app/candidates")

      refute has_element?(index_view, ~s{a[href="/app/candidates/merge"]}, "Duplicates")
      refute html =~ ~r/rounded-full px-1\.5 py-0\.5">\s*1\s*<\/span>/
    end

    test "add candidate upserts an existing active candidate by email", %{conn: conn} do
      {tenant, user} = setup_tenant()
      existing = create_candidate(tenant, "Existing Person", "dup@example.com")

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates")

      view |> element("button", "+ Add Candidate") |> render_click()

      view
      |> form("#candidate-form", %{
        "candidate" => %{"name" => "Existing Person", "email" => "DUP@example.com"}
      })
      |> render_submit()

      assert render(view) =~ "Candidate added"

      candidates = Enum.filter(Repo.all(Candidate), &(&1.tenant_id == tenant.id))
      assert length(candidates) == 1
      assert hd(candidates).id == existing.id
    end

    test "bulk merge flow merges selected candidates through the primary picker modal", %{
      conn: conn
    } do
      {tenant, user} = setup_tenant()
      primary = create_candidate(tenant, "Primary Person", "primary@example.com")
      absorbed = create_candidate(tenant, "Absorbed Person", "absorbed@example.com")

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates")

      view |> element(~s{input[phx-value-id="#{primary.id}"]}) |> render_click()
      view |> element(~s{input[phx-value-id="#{absorbed.id}"]}) |> render_click()

      view
      |> element("select[name=bulk_action]")
      |> render_change(%{"bulk_action" => "merge"})

      assert has_element?(view, "button", "Merge...")

      view |> element("button", "Merge...") |> render_click()
      assert has_element?(view, "h3", "Merge candidates")

      view
      |> element(~s{input[phx-value-candidate_id="#{primary.id}"]})
      |> render_click()

      view
      |> element(~s{button[phx-click="do_bulk_execute_merge"]})
      |> render_click()

      assert render(view) =~ "Merged candidates into Primary Person"
      assert Repo.get!(Candidate, absorbed.id).merged_into_id == primary.id
    end
  end

  describe "absorbed candidate redirect" do
    test "redirects to the primary profile with a merged notice", %{conn: conn} do
      {tenant, user} = setup_tenant()
      primary = create_candidate(tenant, "Primary Person", "primary@example.com")
      absorbed = create_candidate(tenant, "Absorbed Person", "absorbed@example.com")

      {:ok, _} = Candidates.merge_candidates(primary, [absorbed], user)

      conn = login_user(conn, user)

      assert {:error, {:live_redirect, %{to: to}}} =
               live(conn, ~p"/app/candidates/#{absorbed.id}")

      assert to == "/app/candidates/#{primary.id}"

      {:ok, _view, html} = live(conn, to)
      assert html =~ "Primary Person"
    end
  end

  describe "undo merge" do
    test "undoes a merge from the primary show page and restores the absorbed profile", %{
      conn: conn
    } do
      {tenant, user} = setup_tenant()
      primary = create_candidate(tenant, "Primary Person", "primary@example.com")
      absorbed = create_candidate(tenant, "Absorbed Person", "absorbed@example.com")

      {:ok, _} = Candidates.merge_candidates(primary, [absorbed], user)

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/#{primary.id}")

      assert render(view) =~ ~r/This profile absorbed 1 duplicate\s*profile/
      assert has_element?(view, "button", "Undo merge")

      view |> element("button", "Undo merge") |> render_click()

      assert render(view) =~ "Merge undone"
      refute render(view) =~ "This profile absorbed 1 duplicate profile"

      assert Repo.get!(Candidate, absorbed.id).merged_into_id == nil
      assert Repo.get!(Candidate, primary.id).merged_into_id == nil
    end
  end
end
