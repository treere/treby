defmodule TrebyWeb.CandidatePortalLiveTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Candidates, Pipeline, CandidatePortal, Repo}
  alias Treby.Jobs.Job
  alias Treby.Pipeline.PipelineStage

  defp setup_tenant_and_candidate do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Portal Test Corp",
        slug: "portal-test-#{System.unique_integer([:positive])}"
      })

    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidates.Candidate.changeset(%{
        name: "Portal Candidate",
        email: "portal-candidate-#{System.unique_integer([:positive])}@test.com"
      })
      |> Repo.insert()

    pipeline_id = Pipeline.default_pipeline_id(tenant.id)
    pipeline = Repo.get!(Treby.Pipeline.Pipeline, pipeline_id)

    {:ok, stage} =
      pipeline
      |> Ecto.build_assoc(:pipeline_stages)
      |> PipelineStage.changeset(%{
        name: "Applied",
        position: 0
      })
      |> Repo.insert()

    {:ok, job} =
      tenant
      |> Ecto.build_assoc(:jobs)
      |> Job.changeset(%{
        title: "Portal Test Job",
        status: "open",
        stage: "all",
        description: "Test job description"
      })
      |> Repo.insert()

    {:ok, application} =
      %Treby.Pipeline.Application{}
      |> Treby.Pipeline.Application.changeset(%{
        candidate_id: candidate.id,
        job_id: job.id,
        pipeline_stage_id: stage.id,
        applied_at: DateTime.utc_now(),
        tenant_id: tenant.id
      })
      |> Repo.insert()

    {tenant, candidate, application}
  end

  defp login_candidate_via_session(conn, candidate, tenant) do
    conn
    |> init_test_session(%{
      "candidate_id" => candidate.id,
      "candidate_tenant_id" => tenant.id
    })
  end

  describe "portal index" do
    test "shows dashboard with applications", %{conn: conn} do
      {tenant, candidate, application} = setup_tenant_and_candidate()

      _conversation =
        CandidatePortal.create_conversation(%{
          candidate_id: candidate.id,
          tenant_id: tenant.id,
          subject: "Test Conversation",
          context: "application",
          application_id: application.id
        })

      conn = login_candidate_via_session(conn, candidate, tenant)
      {:ok, view, _html} = live(conn, ~p"/#{tenant.slug}/portal")

      html = render(view)
      assert html =~ "Portal Test Job"
    end

    test "shows empty state when no applications", %{conn: conn} do
      {:ok, tenant} =
        Tenants.create_tenant(%{
          name: "Empty Portal Corp",
          slug: "empty-portal-#{System.unique_integer([:positive])}"
        })

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidates.Candidate.changeset(%{
          name: "Empty Candidate",
          email: "empty-candidate-#{System.unique_integer([:positive])}@test.com"
        })
        |> Repo.insert()

      conn = login_candidate_via_session(conn, candidate, tenant)
      {:ok, view, _html} = live(conn, ~p"/#{tenant.slug}/portal")

      html = render(view)
      assert html =~ "No applications yet"
    end
  end

  describe "portal messages" do
    test "shows conversation list", %{conn: conn} do
      {tenant, candidate, application} = setup_tenant_and_candidate()

      _conversation =
        CandidatePortal.create_conversation(%{
          candidate_id: candidate.id,
          tenant_id: tenant.id,
          subject: "Welcome Message",
          context: "application",
          application_id: application.id
        })

      conn = login_candidate_via_session(conn, candidate, tenant)
      {:ok, view, _html} = live(conn, ~p"/#{tenant.slug}/portal/messages")

      html = render(view)
      assert html =~ "Welcome Message"
    end

    test "navigates to message thread", %{conn: conn} do
      {tenant, candidate, application} = setup_tenant_and_candidate()

      {:ok, conversation} =
        CandidatePortal.create_conversation(%{
          candidate_id: candidate.id,
          tenant_id: tenant.id,
          subject: "Thread Test",
          context: "application",
          application_id: application.id
        })

      conn = login_candidate_via_session(conn, candidate, tenant)
      {:ok, _view, _html} = live(conn, ~p"/#{tenant.slug}/portal/messages")

      {:ok, thread_view, _html} =
        live(conn, ~p"/#{tenant.slug}/portal/messages/#{conversation.id}")

      html = render(thread_view)
      assert html =~ "Thread Test"
    end
  end

  describe "portal message thread" do
    test "shows conversation messages", %{conn: conn} do
      {tenant, candidate, application} = setup_tenant_and_candidate()

      {:ok, conversation} =
        CandidatePortal.create_conversation(
          %{
            candidate_id: candidate.id,
            tenant_id: tenant.id,
            subject: "Thread Messages",
            context: "application",
            application_id: application.id
          },
          "System message body"
        )

      CandidatePortal.send_message(%{
        sender_type: "candidate",
        conversation_id: conversation.id,
        body: "My reply",
        message_type: "text"
      })

      conn = login_candidate_via_session(conn, candidate, tenant)
      {:ok, view, _html} = live(conn, ~p"/#{tenant.slug}/portal/messages/#{conversation.id}")

      html = render(view)
      assert html =~ "Thread Messages"
      assert html =~ "System message body"
      assert html =~ "My reply"
    end

    test "can send a reply", %{conn: conn} do
      {tenant, candidate, application} = setup_tenant_and_candidate()

      {:ok, conversation} =
        CandidatePortal.create_conversation(%{
          candidate_id: candidate.id,
          tenant_id: tenant.id,
          subject: "Reply Test",
          context: "application",
          application_id: application.id
        })

      conn = login_candidate_via_session(conn, candidate, tenant)
      {:ok, view, _html} = live(conn, ~p"/#{tenant.slug}/portal/messages/#{conversation.id}")

      html =
        view
        |> form("form[phx-submit=\"send_message\"]")
        |> render_submit(%{"message" => "Hello from candidate"})

      assert html =~ "Hello from candidate"
    end
  end

  describe "portal settings" do
    test "shows notification preferences", %{conn: conn} do
      {tenant, candidate, _application} = setup_tenant_and_candidate()

      conn = login_candidate_via_session(conn, candidate, tenant)
      {:ok, view, _html} = live(conn, ~p"/#{tenant.slug}/portal/settings")

      html = render(view)
      assert html =~ "Notification Preferences"
      assert html =~ "New messages"
    end

    test "can toggle preference", %{conn: conn} do
      {tenant, candidate, _application} = setup_tenant_and_candidate()

      conn = login_candidate_via_session(conn, candidate, tenant)
      {:ok, view, _html} = live(conn, ~p"/#{tenant.slug}/portal/settings")

      view
      |> element(~s(button[phx-click="toggle_preference"][phx-value-key="new_message"]))
      |> render_click()

      updated = Repo.get!(Candidates.Candidate, candidate.id)
      prefs = CandidatePortal.get_notification_preferences(updated)
      assert prefs["new_message"] == false
    end
  end
end
