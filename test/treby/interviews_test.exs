defmodule Treby.InterviewsTest do
  use Treby.DataCase, async: true

  import Swoosh.TestAssertions

  alias Plug.Conn
  alias Treby.Interviews
  alias Treby.Interviews.InterviewEvent

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

    test "posts interview message to the candidate's portal conversation", %{
      user: user,
      interviewer: interviewer,
      tenant: tenant
    } do
      attrs = valid_interview_attrs(user.id, interviewer.id, tenant.id)

      {:ok, event} = Interviews.schedule_interview(attrs)
      event = Treby.Repo.preload(event, application: [:candidate, :job])

      conversations =
        Treby.CandidatePortal.list_conversations_for_application(
          event.application.id,
          tenant.id
        )

      assert length(conversations) == 1
      conversation = List.first(conversations)
      messages = Treby.Repo.preload(conversation, :messages).messages

      assert length(messages) == 1
      assert List.first(messages).message_type == "interview_invite"
      assert List.first(messages).body =~ "has been scheduled"
      assert List.first(messages).body =~ "Meeting Link"

      assert_email_sent(
        to: [{"", event.application.candidate.email}],
        subject: "Interview update: #{event.application.job.title}"
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

    test "deletes the external event using the calendar owner's connection", %{
      user: user,
      interviewer: interviewer,
      tenant: tenant
    } do
      # The scheduler (user) is NOT connected; only the owner (interviewer) is.
      {:ok, _} =
        Treby.Calendar.connect_google_user(interviewer.id, tenant.id, %{
          access_token: "access",
          refresh_token: "refresh",
          expires_at: DateTime.utc_now() |> DateTime.add(1, :hour),
          email: "interviewer@gmail.com"
        })

      attrs =
        valid_interview_attrs(user.id, interviewer.id, tenant.id)
        |> Map.put(:provider_event_id, "evt-123")
        |> Map.put(:calendar_provider, "google")
        |> Map.put(:calendar_owner_id, interviewer.id)

      {:ok, event} = Interviews.schedule_interview(attrs)

      Req.Test.stub(Treby.GoogleApiMock, fn conn ->
        assert conn.request_path == "/calendar/v3/calendars/primary/events/evt-123"
        send(self(), {:delete_called, conn.request_path})
        Conn.send_resp(conn, 204, "")
      end)

      assert {:ok, cancelled} = Interviews.cancel_interview(event)
      assert cancelled.status == "cancelled"
      assert_receive {:delete_called, "/calendar/v3/calendars/primary/events/evt-123"}
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
