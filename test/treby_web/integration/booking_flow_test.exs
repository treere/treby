defmodule TrebyWeb.BookingFlowTest do
  use TrebyWeb.ConnCase, async: false

  import Ecto.Query
  import Phoenix.LiveViewTest
  import Req.Test

  alias Treby.{Tenants, Pipeline, Calendar, Repo}
  alias Treby.Accounts.User
  alias Treby.Candidates.Candidate
  alias Treby.Jobs.Job
  alias Treby.Pipeline.PipelineStage
  alias Treby.Availability.AvailabilityRule
  alias Treby.Interviews.InterviewEvent
  alias Treby.GoogleApiMock

  defp setup_tenant_and_admin do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Booking Flow Corp",
        slug: "booking-flow-#{System.unique_integer([:positive])}"
      })

    {:ok, admin} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "admin-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Admin User",
        role: "admin"
      })
      |> Repo.insert()

    {tenant, admin}
  end

  defp setup_examiner(tenant, connected_to_google? \\ false) do
    {:ok, examiner} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "examiner-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Examiner User"
      })
      |> Repo.insert()

    {:ok, _} =
      AvailabilityRule.changeset(%AvailabilityRule{}, %{
        user_id: examiner.id,
        tenant_id: tenant.id,
        day_of_week: Date.day_of_week(Date.utc_today()),
        start_time: ~T[09:00:00],
        end_time: ~T[17:00:00],
        timezone: "UTC",
        buffer_before: 0,
        buffer_after: 0
      })
      |> Repo.insert()

    interview_stage =
      Repo.one!(from s in PipelineStage, where: s.stage_type == "interview", limit: 1)

    Pipeline.assign_examiner(interview_stage, examiner.id)

    if connected_to_google? do
      {:ok, _} =
        Calendar.connect_google_user(examiner.id, tenant.id, %{
          access_token: "test-access-token",
          refresh_token: "test-refresh-token",
          expires_at: DateTime.utc_now() |> DateTime.add(1, :hour),
          email: examiner.email
        })
    end

    examiner
  end

  defp setup_application(tenant) do
    pipeline_id = Pipeline.default_pipeline_id(tenant.id)

    {:ok, job} =
      tenant
      |> Ecto.build_assoc(:jobs)
      |> Job.changeset(%{
        title: "Engineer",
        description: "A test job",
        pipeline_id: pipeline_id
      })
      |> Repo.insert()

    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidate.changeset(%{
        name: "Jane Candidate",
        email: "jane-#{System.unique_integer([:positive])}@test.com"
      })
      |> Repo.insert()

    first_stage = Repo.one!(from s in PipelineStage, order_by: [asc: s.position], limit: 1)

    {:ok, application} =
      tenant
      |> Ecto.build_assoc(:applications)
      |> Ecto.Changeset.change(%{
        job_id: job.id,
        candidate_id: candidate.id,
        pipeline_stage_id: first_stage.id,
        applied_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Repo.insert()

    %{job: job, candidate: candidate, application: application}
  end

  defp login_admin(conn, admin) do
    conn
    |> init_test_session(%{"user_id" => admin.id, "tenant_id" => admin.tenant_id})
  end

  defp book_first_slot(view) do
    html = render(view)
    [slot_start] = Regex.run(~r/phx-value-start="([^"]+)"/, html, capture: :all_but_first)

    view
    |> element(~s{button[phx-value-start="#{slot_start}"]})
    |> render_click()

    view |> element("button", "Book Interview") |> render_click()
  end

  describe "recruiter booking" do
    test "books with a Jitsi link when no examiner is Google-connected", %{conn: conn} do
      {tenant, admin} = setup_tenant_and_admin()
      _examiner = setup_examiner(tenant)
      data = setup_application(tenant)

      conn = login_admin(conn, admin)
      {:ok, view, _html} = live(conn, ~p"/app/schedule/#{data.application.id}")

      view |> element("button", "Examiner User") |> render_click()
      book_first_slot(view)

      event =
        Repo.one!(from e in InterviewEvent, where: e.application_id == ^data.application.id)

      assert event.video_conf_url =~ ~r|^https://meet\.jit\.si/treby-booking-flow-|
      assert is_nil(event.provider_event_id)
      assert is_nil(event.calendar_provider)
      assert is_nil(event.calendar_owner_id)
    end

    test "books with a Google event when an examiner is Google-connected", %{conn: conn} do
      {tenant, admin} = setup_tenant_and_admin()
      examiner = setup_examiner(tenant, true)
      data = setup_application(tenant)

      GoogleApiMock.stub_free_busy([])
      GoogleApiMock.stub_event_create("evt-booking", "https://meet.google.com/booking-link")

      conn = login_admin(conn, admin)
      {:ok, view, _html} = live(conn, ~p"/app/schedule/#{data.application.id}")

      allow(Treby.GoogleApiMock, self(), view.pid)

      view |> element("button", "Examiner User") |> render_click()
      book_first_slot(view)

      event =
        Repo.one!(from e in InterviewEvent, where: e.application_id == ^data.application.id)

      assert event.video_conf_url == "https://meet.google.com/booking-link"
      assert event.provider_event_id == "evt-booking"
      assert event.calendar_provider == "google"
      assert event.calendar_owner_id == examiner.id
    end
  end
end
