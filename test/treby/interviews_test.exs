defmodule Treby.InterviewsTest do
  use Treby.DataCase, async: true

  import Swoosh.TestAssertions

  alias Treby.Interviews
  alias Treby.Interviews.InterviewEvent
  alias Treby.Interviews.BookingToken

  setup do
    {:ok, tenant} = insert_tenant()
    {:ok, user} = insert_user(tenant.id)
    {:ok, interviewer} = insert_user(tenant.id)
    {:ok, tenant: tenant, user: user, interviewer: interviewer}
  end

  describe "schedule_interview/1" do
    test "creates interview event with valid attrs", %{
      user: user,
      interviewer: interviewer,
      tenant: tenant
    } do
      attrs = valid_interview_attrs(user.id, interviewer.id, tenant.id)

      assert {:ok, %InterviewEvent{} = event} = Interviews.schedule_interview(attrs)
      assert event.status == "scheduled"
      assert event.duration_minutes == 30
    end

    test "sends confirmation email to the candidate", %{
      user: user,
      interviewer: interviewer,
      tenant: tenant
    } do
      attrs = valid_interview_attrs(user.id, interviewer.id, tenant.id)

      {:ok, event} = Interviews.schedule_interview(attrs)
      event = Treby.Repo.preload(event, application: [:candidate, :job])

      assert_email_sent(
        to: [{"", event.application.candidate.email}],
        subject: "Interview Scheduled - #{event.application.job.title}"
      )
    end

    test "returns error with invalid attrs" do
      assert {:error, changeset} = Interviews.schedule_interview(%{})
      assert errors_on(changeset) |> Map.has_key?(:application_id)
    end
  end

  describe "cancel_interview/1" do
    test "cancels a scheduled interview", %{user: user, interviewer: interviewer, tenant: tenant} do
      {:ok, event} =
        Interviews.schedule_interview(valid_interview_attrs(user.id, interviewer.id, tenant.id))

      assert {:ok, cancelled} = Interviews.cancel_interview(event)
      assert cancelled.status == "cancelled"
    end
  end

  describe "list_upcoming_for_user/1" do
    test "returns upcoming interviews for a user", %{
      user: user,
      interviewer: interviewer,
      tenant: tenant
    } do
      attrs =
        valid_interview_attrs(user.id, interviewer.id, tenant.id)
        |> Map.put(:start_at_utc, DateTime.add(DateTime.utc_now(), 1, :day))
        |> Map.put(
          :end_at_utc,
          DateTime.add(DateTime.utc_now(), 1, :day) |> DateTime.add(1800, :second)
        )
        |> Map.put(:examiner_ids, [interviewer.id])

      {:ok, _event} = Interviews.schedule_interview(attrs)

      upcoming = Interviews.list_upcoming_for_user(interviewer.id)
      assert length(upcoming) == 1
    end

    test "does not return past interviews", %{
      user: user,
      interviewer: interviewer,
      tenant: tenant
    } do
      attrs =
        valid_interview_attrs(user.id, interviewer.id, tenant.id)
        |> Map.put(:start_at_utc, DateTime.add(DateTime.utc_now(), -1, :day))
        |> Map.put(
          :end_at_utc,
          DateTime.add(DateTime.utc_now(), -1, :day) |> DateTime.add(1800, :second)
        )

      {:ok, _event} = Interviews.schedule_interview(attrs)

      upcoming = Interviews.list_upcoming_for_user(interviewer.id)
      assert upcoming == []
    end
  end

  describe "list_for_application/1" do
    test "returns all interviews for an application", %{
      user: user,
      interviewer: interviewer,
      tenant: tenant
    } do
      {:ok, job} = insert_job(tenant.id)
      {:ok, candidate} = insert_candidate(tenant.id)
      {:ok, app} = insert_application(tenant.id, job.id, candidate.id)

      attrs =
        valid_interview_attrs(user.id, interviewer.id, tenant.id)
        |> Map.put(:application_id, app.id)

      {:ok, _event} = Interviews.schedule_interview(attrs)

      interviews = Interviews.list_for_application(app.id)
      assert length(interviews) == 1
    end
  end

  describe "booking tokens" do
    test "generate_booking_token/1 creates token with expiry", %{
      user: _user,
      interviewer: interviewer,
      tenant: tenant
    } do
      {:ok, job} = insert_job(tenant.id)
      {:ok, candidate} = insert_candidate(tenant.id)
      {:ok, app} = insert_application(tenant.id, job.id, candidate.id)

      attrs = %{
        application_id: app.id,
        interviewer_id: interviewer.id,
        tenant_id: tenant.id
      }

      assert {:ok, %BookingToken{} = token} = Interviews.generate_booking_token(attrs)
      assert token.token != nil
      assert DateTime.after?(token.expires_at, DateTime.utc_now())
      assert token.used_at == nil
    end

    test "get_booking_token/1 returns valid unused token", %{
      interviewer: interviewer,
      tenant: tenant
    } do
      {:ok, job} = insert_job(tenant.id)
      {:ok, candidate} = insert_candidate(tenant.id)
      {:ok, app} = insert_application(tenant.id, job.id, candidate.id)

      {:ok, token} =
        Interviews.generate_booking_token(%{
          application_id: app.id,
          interviewer_id: interviewer.id,
          tenant_id: tenant.id
        })

      found = Interviews.get_booking_token(token.token)
      assert found.id == token.id
    end

    test "get_booking_token/1 returns nil for used token", %{
      interviewer: interviewer,
      tenant: tenant
    } do
      {:ok, job} = insert_job(tenant.id)
      {:ok, candidate} = insert_candidate(tenant.id)
      {:ok, app} = insert_application(tenant.id, job.id, candidate.id)

      {:ok, token} =
        Interviews.generate_booking_token(%{
          application_id: app.id,
          interviewer_id: interviewer.id,
          tenant_id: tenant.id
        })

      {:ok, _} = Interviews.use_booking_token(token)
      assert Interviews.get_booking_token(token.token) == nil
    end

    test "get_booking_token/1 returns nil for expired token", %{
      interviewer: interviewer,
      tenant: tenant
    } do
      {:ok, job} = insert_job(tenant.id)
      {:ok, candidate} = insert_candidate(tenant.id)
      {:ok, app} = insert_application(tenant.id, job.id, candidate.id)

      {:ok, token} =
        Interviews.generate_booking_token(%{
          application_id: app.id,
          interviewer_id: interviewer.id,
          tenant_id: tenant.id
        })

      # Manually expire the token
      token
      |> BookingToken.changeset(%{expires_at: DateTime.add(DateTime.utc_now(), -1, :day)})
      |> Treby.Repo.update()

      assert Interviews.get_booking_token(token.token) == nil
    end

    test "use_booking_token/1 marks token as used", %{
      interviewer: interviewer,
      tenant: tenant
    } do
      {:ok, job} = insert_job(tenant.id)
      {:ok, candidate} = insert_candidate(tenant.id)
      {:ok, app} = insert_application(tenant.id, job.id, candidate.id)

      {:ok, token} =
        Interviews.generate_booking_token(%{
          application_id: app.id,
          interviewer_id: interviewer.id,
          tenant_id: tenant.id
        })

      assert {:ok, used} = Interviews.use_booking_token(token)
      assert used.used_at != nil
    end
  end

  defp valid_interview_attrs(scheduled_by_id, interviewer_id, tenant_id) do
    {:ok, job} = insert_job(tenant_id)
    {:ok, candidate} = insert_candidate(tenant_id)
    {:ok, app} = insert_application(tenant_id, job.id, candidate.id)

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    %{
      start_at_utc: DateTime.add(now, 1, :day),
      end_at_utc: DateTime.add(now, 1, :day) |> DateTime.add(1800, :second),
      duration_minutes: 30,
      interviewer_id: interviewer_id,
      scheduled_by_id: scheduled_by_id,
      application_id: app.id,
      tenant_id: tenant_id,
      examiner_ids: [interviewer_id]
    }
  end

  defp insert_tenant do
    tenant =
      Treby.Repo.insert!(%Treby.Tenants.Tenant{
        name: "Test Tenant",
        slug: "test-#{System.unique_integer([:positive])}"
      })

    Treby.Pipeline.create_default_pipeline_stages(tenant)

    {:ok, tenant}
  end

  defp insert_user(tenant_id) do
    Treby.Repo.insert!(%Treby.Accounts.User{
      name: "Test User",
      email: "test-#{System.unique_integer([:positive])}@example.com",
      password_hash: Bcrypt.hash_pwd_salt("password123456"),
      tenant_id: tenant_id
    })
    |> then(&{:ok, &1})
  end

  defp insert_job(tenant_id) do
    pipeline_id = Treby.Pipeline.default_pipeline_id(tenant_id)

    {:ok, job} =
      %Treby.Jobs.Job{}
      |> Ecto.Changeset.change(%{
        title: "Test Job",
        description: "A test job posting",
        tenant_id: tenant_id,
        pipeline_id: pipeline_id
      })
      |> Treby.Repo.insert()

    {:ok, job}
  end

  defp insert_candidate(tenant_id) do
    {:ok, candidate} =
      %Treby.Candidates.Candidate{}
      |> Ecto.Changeset.change(%{
        name: "Test Candidate",
        email: "candidate-#{System.unique_integer([:positive])}@example.com",
        tenant_id: tenant_id
      })
      |> Treby.Repo.insert()

    {:ok, candidate}
  end

  defp insert_application(_tenant_id, job_id, candidate_id) do
    job = Treby.Repo.get!(Treby.Jobs.Job, job_id)
    pipeline_id = job.pipeline_id || Treby.Pipeline.default_pipeline_id(job.tenant_id)

    stage =
      case Treby.Repo.one(
             from s in Treby.Pipeline.PipelineStage,
               where: s.pipeline_id == ^pipeline_id,
               limit: 1
           ) do
        nil ->
          {:ok, stage} =
            %Treby.Pipeline.PipelineStage{}
            |> Ecto.Changeset.change(%{
              name: "Applied",
              position: 0,
              color: "#3B82F6",
              pipeline_id: pipeline_id
            })
            |> Treby.Repo.insert()

          stage

        existing ->
          existing
      end

    {:ok, app} =
      %Treby.Pipeline.Application{}
      |> Ecto.Changeset.change(%{
        job_id: job_id,
        candidate_id: candidate_id,
        pipeline_stage_id: stage.id,
        tenant_id: job.tenant_id,
        applied_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Treby.Repo.insert()

    {:ok, app}
  end
end
