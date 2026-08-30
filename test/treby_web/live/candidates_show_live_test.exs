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

  describe "candidate conversations realtime" do
    test "shows candidate messages in realtime without reload", %{conn: conn} do
      {tenant, user} = setup_tenant()
      candidate = create_candidate(tenant, "Realtime Candidate")

      {:ok, conversation} =
        Treby.CandidatePortal.create_conversation(%{
          candidate_id: candidate.id,
          tenant_id: tenant.id,
          subject: "Realtime Conversation"
        })

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/candidates/#{candidate.id}")

      refute render(view) =~ "Realtime from candidate"

      Treby.CandidatePortal.send_message(%{
        sender_type: "candidate",
        body: "Realtime from candidate",
        message_type: "text",
        conversation_id: conversation.id
      })

      assert render(view) =~ "Realtime from candidate"
    end
  end

  describe "contextual back navigation" do
    test "back link returns to the originating job page", %{conn: conn} do
      {tenant, user} = setup_tenant()
      candidate = create_candidate(tenant, "Back Nav Candidate")

      conn = login_user(conn, user)

      {:ok, _view, html} =
        live(conn, ~p"/app/candidates/#{candidate.id}?return_to=/app/jobs/job-123")

      assert html =~ "Back to Job"
      assert html =~ ~p"/app/jobs/job-123"
    end

    test "back link returns to the pipeline board", %{conn: conn} do
      {tenant, user} = setup_tenant()
      candidate = create_candidate(tenant, "Back Nav Pipeline")

      conn = login_user(conn, user)

      {:ok, _view, html} =
        live(conn, ~p"/app/candidates/#{candidate.id}?return_to=/app/pipeline/job-123")

      assert html =~ "Back to Pipeline"
      assert html =~ ~p"/app/pipeline/job-123"
    end

    test "back link falls back to candidates for direct visits", %{conn: conn} do
      {tenant, user} = setup_tenant()
      candidate = create_candidate(tenant, "Back Nav Direct")

      conn = login_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/app/candidates/#{candidate.id}")

      assert html =~ "Back to Candidates"
      assert html =~ ~p"/app/candidates"
    end

    test "back link falls back to candidates for invalid return paths", %{conn: conn} do
      {tenant, user} = setup_tenant()
      candidate = create_candidate(tenant, "Back Nav Invalid")

      conn = login_user(conn, user)

      {:ok, _view, html} =
        live(conn, ~p"/app/candidates/#{candidate.id}?return_to=https://evil.com")

      assert html =~ "Back to Candidates"
      assert html =~ ~p"/app/candidates"
    end
  end

  describe "scheduled interviews on profile" do
    test "renders candidate profile with interviews and examiner names without crashing", %{
      conn: conn
    } do
      {tenant, user} = setup_tenant()
      candidate = create_candidate(tenant, "Interview Candidate")

      pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)

      {:ok, job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Treby.Jobs.Job.changeset(%{
          title: "Interview Job",
          description: "Desc",
          pipeline_id: pipeline_id
        })
        |> Treby.Repo.insert()

      stage =
        Treby.Pipeline.list_pipeline_stages(pipeline_id)
        |> Enum.find(&(&1.stage_type == "interview")) ||
          List.first(Treby.Pipeline.list_pipeline_stages(pipeline_id))

      {:ok, application} =
        Treby.Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: stage.id,
          applied_at: DateTime.utc_now()
        })

      now = DateTime.utc_now() |> DateTime.truncate(:second)

      {:ok, event} =
        %Treby.Interviews.InterviewEvent{}
        |> Treby.Interviews.InterviewEvent.changeset(%{
          start_at_utc: DateTime.add(now, 3600),
          end_at_utc: DateTime.add(now, 5400),
          duration_minutes: 30,
          application_id: application.id,
          tenant_id: tenant.id,
          status: "scheduled"
        })
        |> Treby.Repo.insert()

      %Treby.Interviews.EventExaminer{}
      |> Treby.Interviews.EventExaminer.changeset(%{
        interview_event_id: event.id,
        user_id: user.id
      })
      |> Treby.Repo.insert!()

      conn = login_user(conn, user)
      {:ok, view, html} = live(conn, ~p"/app/candidates/#{candidate.id}")

      assert html =~ "Scheduled Interviews"
      assert html =~ user.name
      assert has_element?(view, "h1", candidate.name)
    end
  end
end
