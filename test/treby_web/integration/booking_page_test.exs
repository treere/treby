defmodule TrebyWeb.BookingPageTest do
  use TrebyWeb.ConnCase, async: false

  import Ecto.Query

  alias Treby.{Tenants, Pipeline, Calendar, Availability, Repo}
  alias Treby.Accounts.User

  defp setup_tenant_and_user do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Booking Test Corp",
        slug: "booking-test-#{System.unique_integer([:positive])}"
      })

    Pipeline.create_default_pipeline_stages(tenant)

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "admin-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Admin User",
        role: "admin"
      })
      |> Repo.insert()

    {tenant, user}
  end

  defp setup_interviewer_with_availability(tenant) do
    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "interviewer-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Interviewer User",
        role: "admin"
      })
      |> Repo.insert()

    {:ok, _} =
      Calendar.connect_google_user(user.id, tenant.id, %{
        access_token: "test-access-token",
        refresh_token: "test-refresh-token",
        expires_at: DateTime.utc_now() |> DateTime.add(1, :hour),
        email: user.email
      })

    # Create availability rules for every day of the week
    for day <- 1..7 do
      Availability.create_rule(%{
        user_id: user.id,
        tenant_id: tenant.id,
        day_of_week: day,
        start_time: ~T[09:00:00],
        end_time: ~T[17:00:00],
        timezone: "UTC",
        buffer_before: 0,
        buffer_after: 0
      })
    end

    user
  end

  defp setup_candidate_and_app(tenant) do
    {:ok, job} =
      tenant
      |> Ecto.build_assoc(:jobs)
      |> Treby.Jobs.Job.changeset(%{
        title: "Test Engineer",
        description: "A test job"
      })
      |> Repo.insert()

    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Treby.Candidates.Candidate.changeset(%{
        name: "Test Candidate",
        email: "candidate-#{System.unique_integer([:positive])}@test.com"
      })
      |> Repo.insert()

    stage =
      Repo.one!(from s in Pipeline.PipelineStage, where: s.tenant_id == ^tenant.id, limit: 1)

    {:ok, application} =
      tenant
      |> Ecto.build_assoc(:applications)
      |> Ecto.Changeset.change(%{
        job_id: job.id,
        candidate_id: candidate.id,
        pipeline_stage_id: stage.id,
        applied_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Repo.insert()

    {job, candidate, application}
  end

  describe "public booking page" do
    test "shows invalid link page for expired token", %{conn: conn} do
      {tenant, _user} = setup_tenant_and_user()
      interviewer = setup_interviewer_with_availability(tenant)
      {_job, _candidate, app} = setup_candidate_and_app(tenant)

      {:ok, token} =
        Treby.Interviews.generate_booking_token(%{
          application_id: app.id,
          interviewer_id: interviewer.id,
          tenant_id: tenant.id
        })

      # Expire the token
      token
      |> Treby.Interviews.BookingToken.changeset(%{
        expires_at: DateTime.add(DateTime.utc_now(), -1, :day)
      })
      |> Repo.update()

      conn = get(conn, ~p"/#{tenant.slug}/schedule/#{token.token}")

      assert html_response(conn, 200) =~ "Invalid or Expired Link"

      assert html_response(conn, 200) =~
               "This scheduling link has expired or has already been used"
    end

    test "shows invalid link page for used token", %{conn: conn} do
      {tenant, _user} = setup_tenant_and_user()
      interviewer = setup_interviewer_with_availability(tenant)
      {_job, _candidate, app} = setup_candidate_and_app(tenant)

      {:ok, token} =
        Treby.Interviews.generate_booking_token(%{
          application_id: app.id,
          interviewer_id: interviewer.id,
          tenant_id: tenant.id
        })

      # Use the token
      Treby.Interviews.use_booking_token(token)

      conn = get(conn, ~p"/#{tenant.slug}/schedule/#{token.token}")

      assert html_response(conn, 200) =~ "Invalid or Expired Link"
    end

    test "shows invalid link page for nonexistent token", %{conn: conn} do
      {tenant, _user} = setup_tenant_and_user()

      conn = get(conn, ~p"/#{tenant.slug}/schedule/nonexistent-token")

      assert html_response(conn, 200) =~ "Invalid or Expired Link"
    end

    test "shows booking page for valid token with interviewer", %{conn: conn} do
      {tenant, _user} = setup_tenant_and_user()
      interviewer = setup_interviewer_with_availability(tenant)
      {_job, _candidate, app} = setup_candidate_and_app(tenant)

      {:ok, token} =
        Treby.Interviews.generate_booking_token(%{
          application_id: app.id,
          interviewer_id: interviewer.id,
          tenant_id: tenant.id
        })

      conn = get(conn, ~p"/#{tenant.slug}/schedule/#{token.token}")

      html = html_response(conn, 200)
      assert html =~ "Schedule your interview"
      assert html =~ "Interviewer User"
      assert html =~ "Test Engineer"
    end

    test "shows booking page for valid token without interviewer", %{conn: conn} do
      {tenant, _user} = setup_tenant_and_user()
      {_job, _candidate, app} = setup_candidate_and_app(tenant)

      {:ok, token} =
        Treby.Interviews.generate_booking_token(%{
          application_id: app.id,
          tenant_id: tenant.id
        })

      conn = get(conn, ~p"/#{tenant.slug}/schedule/#{token.token}")

      html = html_response(conn, 200)
      assert html =~ "Schedule your interview"
      assert html =~ "Test Engineer"
    end
  end
end
