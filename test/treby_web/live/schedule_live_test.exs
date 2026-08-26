defmodule TrebyWeb.ScheduleLive.IndexTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User
  alias Treby.Candidates.Candidate
  alias Treby.Jobs.Job
  alias Treby.Pipeline.PipelineStage

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Schedule Test Corp",
        slug: "schedule-test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "schedule-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Schedule User",
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

  defp setup_application(tenant) do
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
        title: "Backend Engineer",
        description: "Build APIs",
        pipeline_id: pipeline_id
      })
      |> Repo.insert()

    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidate.changeset(%{
        name: "Jane Candidate",
        email: "jane-candidate@example.com"
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

    %{job: job, candidate: candidate, application: application}
  end

  describe "booking link email" do
    test "emails the booking link to the candidate", %{conn: conn} do
      {tenant, user} = setup_tenant()
      data = setup_application(tenant)

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/schedule/#{data.application.id}")

      view |> render_click("email_booking_link", %{})

      assert render(view) =~ "Booking link sent to jane-candidate@example.com"

      assert_email_sent(
        to: [{"", "jane-candidate@example.com"}],
        subject: "Book your interview - Backend Engineer"
      )
    end

    test "renders the email booking link button", %{conn: conn} do
      {tenant, user} = setup_tenant()
      data = setup_application(tenant)

      conn = login_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/app/schedule/#{data.application.id}")

      assert html =~ "Email Booking Link"
      assert html =~ "Generate Booking Link"
    end
  end
end
