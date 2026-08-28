defmodule TrebyWeb.CandidatesLive.IndexTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User
  alias Treby.Candidates.Candidate
  alias Treby.Jobs.Job
  alias Treby.Pipeline.PipelineStage

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
        |> Candidate.changeset(%{
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

  describe "search" do
    defp create_candidate(tenant, name, email) do
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidate.changeset(%{name: name, email: email})
      |> Repo.insert!()
    end

    test "search submit filters candidates in place", %{conn: conn} do
      {tenant, user} = setup_tenant()
      create_candidate(tenant, "Carol Williams", "carol@example.com")
      create_candidate(tenant, "Bob Jones", "bob@example.com")
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app/candidates")

      html =
        view
        |> form("form[phx-submit='search_submit']", %{"search" => "carol"})
        |> render_submit()

      assert html =~ "Carol Williams"
      refute html =~ "Bob Jones"
    end

    test "search param in URL filters on load and pre-fills the input", %{conn: conn} do
      {tenant, user} = setup_tenant()
      create_candidate(tenant, "Carol Williams", "carol@example.com")
      create_candidate(tenant, "Bob Jones", "bob@example.com")
      conn = login_user(conn, user)

      {:ok, _view, html} = live(conn, ~p"/app/candidates?search=carol")

      assert html =~ "Carol Williams"
      refute html =~ "Bob Jones"
      assert html =~ ~s{value="carol"}
    end

    test "clearing the search input shows all candidates again", %{conn: conn} do
      {tenant, user} = setup_tenant()
      create_candidate(tenant, "Carol Williams", "carol@example.com")
      create_candidate(tenant, "Bob Jones", "bob@example.com")
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app/candidates?search=carol")
      assert render(view) =~ "Carol Williams"
      refute render(view) =~ "Bob Jones"

      html =
        view
        |> form("form[phx-submit='search_submit']", %{"search" => ""})
        |> render_submit()

      assert html =~ "Carol Williams"
      assert html =~ "Bob Jones"
    end
  end

  describe "bulk message composer" do
    test "composer form wraps inputs so Enter does not reload the page", %{conn: conn} do
      {tenant, user} = setup_tenant()

      create_candidate(tenant, "Bulk One", "bulk1@example.com")

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates")

      view |> element(~s{input[phx-click="toggle_candidate"]}) |> render_click()

      view
      |> element("select[name=bulk_action]")
      |> render_change(%{"bulk_action" => "send_message"})

      assert has_element?(view, "#bulk-message-composer")

      html =
        view
        |> form("#bulk-message-composer", %{
          "bulk_email_body" => "Hello",
          "bulk_email_mode" => "now"
        })
        |> render_submit()

      refute html =~ "form events require a phx-submit"
    end
  end

  describe "show page - edit validation" do
    test "shows flash error when saving edit with empty name", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{
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

  describe "show page - schedule interview" do
    test "shows a Schedule Interview link per application", %{conn: conn} do
      {tenant, user} = setup_tenant()

      pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)
      pipeline = Repo.get!(Treby.Pipeline.Pipeline, pipeline_id)

      {:ok, stage} =
        pipeline
        |> Ecto.build_assoc(:pipeline_stages)
        |> PipelineStage.changeset(%{
          name: "Applied",
          position: 0,
          stage_type: "applied"
        })
        |> Repo.insert()

      {:ok, job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{
          title: "Platform Engineer",
          description: "Build platform",
          pipeline_id: pipeline_id
        })
        |> Repo.insert()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{
          name: "Schedule Person",
          email: "scheduleperson@example.com"
        })
        |> Repo.insert()

      {:ok, application} =
        Treby.Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: stage.id,
          applied_at: DateTime.utc_now()
        })

      conn = login_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/app/candidates/#{candidate.id}")

      assert html =~ "Schedule Interview"
      assert html =~ "/app/schedule/#{application.id}"
    end
  end

  describe "bulk email - scheduling" do
    defp create_job_pipeline(tenant) do
      {:ok, job} =
        Treby.Jobs.create_job(%{
          tenant_id: tenant.id,
          title: "Engineer",
          description: "Backend engineer"
        })

      {:ok, pipeline} =
        Treby.Pipeline.create_pipeline(%{
          name: "Default",
          tenant_id: tenant.id,
          is_default: true
        })

      {:ok, stage} =
        Treby.Pipeline.create_pipeline_stage(%{
          name: "Applied",
          position: 1,
          pipeline_id: pipeline.id,
          tenant_id: tenant.id,
          stage_type: "applied"
        })

      {job, stage}
    end

    defp create_candidate_with_application(tenant, job, stage, name, email) do
      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{name: name, email: email})
        |> Repo.insert()

      {:ok, _application} =
        Treby.Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: stage.id,
          applied_at: DateTime.utc_now()
        })

      candidate
    end

    test "shows schedule options in bulk composer", %{conn: conn} do
      {tenant, user} = setup_tenant()
      {job, stage} = create_job_pipeline(tenant)

      candidate =
        create_candidate_with_application(tenant, job, stage, "Bulk Test", "bulk@example.com")

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates")

      view |> element(~s{input[phx-value-id="#{candidate.id}"]}) |> render_click()

      view
      |> element("select[name=bulk_action]")
      |> render_change(%{"bulk_action" => "send_message"})

      assert render(view) =~ "Schedule for later"

      view |> element(~s{input[phx-value-mode="schedule"]}) |> render_click()

      assert has_element?(view, "button", "Tomorrow 9:00")
      assert has_element?(view, "button", "Tomorrow 14:00")
      assert has_element?(view, "button", "Next Monday")
    end

    test "schedules bulk messages when schedule mode selected", %{conn: conn} do
      {tenant, user} = setup_tenant()
      {job, stage} = create_job_pipeline(tenant)

      candidate =
        create_candidate_with_application(tenant, job, stage, "Bulk Test", "bulk@example.com")

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates")

      view |> element(~s{input[phx-value-id="#{candidate.id}"]}) |> render_click()

      view
      |> element("select[name=bulk_action]")
      |> render_change(%{"bulk_action" => "send_message"})

      view |> element(~s{input[phx-value-mode="schedule"]}) |> render_click()
      view |> element(~s{button[phx-value-label="tomorrow_9"]}) |> render_click()

      view
      |> element(~s{textarea[name="bulk_email_body"]})
      |> render_change(%{"bulk_email_body" => "Hello {candidate_name}"})

      view |> element("button", "Send") |> render_click()

      assert render(view) =~ "1 messages scheduled"

      conversation =
        Treby.CandidatePortal.list_conversations_for_candidate(candidate.id, tenant.id)
        |> List.first()

      queued =
        Repo.get_by!(Treby.ScheduledMessages.ScheduledMessage, conversation_id: conversation.id)

      assert queued.message_type == "text"
      assert queued.body == "Hello Bulk Test"
    end
  end

  describe "bulk compare" do
    test "shows Compare button after selecting the action", %{conn: conn} do
      {tenant, user} = setup_tenant()
      {job, stage} = create_job_pipeline(tenant)

      alice =
        create_candidate_with_application(
          tenant,
          job,
          stage,
          "Alice Compare",
          "alicec@example.com"
        )

      bob =
        create_candidate_with_application(tenant, job, stage, "Bob Compare", "bobc@example.com")

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates")

      view |> element(~s{input[phx-value-id="#{alice.id}"]}) |> render_click()
      view |> element(~s{input[phx-value-id="#{bob.id}"]}) |> render_click()

      view
      |> element("select[name=bulk_action]")
      |> render_change(%{"bulk_action" => "compare"})

      assert has_element?(view, "button", "Compare")
    end

    test "navigates to compare page with selected candidate ids", %{conn: conn} do
      {tenant, user} = setup_tenant()
      {job, stage} = create_job_pipeline(tenant)

      alice =
        create_candidate_with_application(
          tenant,
          job,
          stage,
          "Alice Compare",
          "alicec2@example.com"
        )

      bob =
        create_candidate_with_application(tenant, job, stage, "Bob Compare", "bobc2@example.com")

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates")

      view |> element(~s{input[phx-value-id="#{alice.id}"]}) |> render_click()
      view |> element(~s{input[phx-value-id="#{bob.id}"]}) |> render_click()

      view
      |> element("select[name=bulk_action]")
      |> render_change(%{"bulk_action" => "compare"})

      view |> element("button", "Compare") |> render_click()

      expected = ~p"/app/candidates/compare?ids=#{Enum.join([bob.id, alice.id], ",")}"
      assert_redirect(view, expected)
    end
  end
end
