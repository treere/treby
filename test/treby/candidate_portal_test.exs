defmodule Treby.CandidatePortalTest do
  use Treby.DataCase

  alias Treby.{Tenants, Candidates, Pipeline, Repo}
  alias Treby.CandidatePortal
  alias Treby.CandidatePortal.Message
  alias Treby.Jobs.Job

  defp setup_tenant_and_job do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Test Corp",
        slug: "test-#{System.unique_integer([:positive])}"
      })

    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidates.Candidate.changeset(%{
        name: "John Doe",
        email: "john-#{System.unique_integer([:positive])}@example.com"
      })
      |> Repo.insert()

    {:ok, job} =
      tenant
      |> Ecto.build_assoc(:jobs)
      |> Job.changeset(%{
        title: "Software Engineer",
        description: "Test job",
        department: "Engineering"
      })
      |> Repo.insert()

    pipeline = Pipeline.default_pipeline_id(tenant.id) |> Pipeline.get_pipeline!()
    first_stage = List.first(Pipeline.list_pipeline_stages(pipeline.id))

    {:ok, application} =
      Pipeline.create_application(%{
        tenant_id: tenant.id,
        job_id: job.id,
        candidate_id: candidate.id,
        pipeline_stage_id: first_stage.id,
        applied_at: DateTime.utc_now()
      })

    {tenant, candidate, application}
  end

  describe "OTP login" do
    setup do
      {tenant, candidate, _application} = setup_tenant_and_job()
      {:ok, tenant: tenant, candidate: candidate}
    end

    test "generate_otp/1 creates a 6-digit code", %{candidate: candidate} do
      assert {:ok, code} = CandidatePortal.generate_otp(candidate)
      assert is_binary(code)
      assert String.length(code) == 6
      assert code =~ ~r/^\d{6}$/
    end

    test "generate_otp/1 stores only the hash", %{candidate: candidate} do
      {:ok, code} = CandidatePortal.generate_otp(candidate)

      otp =
        Repo.one(
          from o in Treby.CandidatePortal.CandidateOtp, where: o.candidate_id == ^candidate.id
        )

      assert otp.code != code
      assert String.length(otp.code) > 0
    end

    test "generate_otp/1 rate limits within cooldown", %{candidate: candidate} do
      assert {:ok, _} = CandidatePortal.generate_otp(candidate)
      assert {:error, :rate_limited} = CandidatePortal.generate_otp(candidate)
    end

    test "generate_otp/1 invalidates previous pending codes", %{candidate: candidate} do
      assert {:ok, _} = CandidatePortal.generate_otp(candidate)
      old_inserted = ~U[2020-01-01 00:00:00Z]

      Repo.update_all(
        from(o in Treby.CandidatePortal.CandidateOtp,
          where: o.candidate_id == ^candidate.id,
          update: [set: [inserted_at: ^old_inserted]]
        ),
        []
      )

      assert {:ok, _} = CandidatePortal.generate_otp(candidate)

      otps =
        Repo.all(
          from o in Treby.CandidatePortal.CandidateOtp, where: o.candidate_id == ^candidate.id
        )

      assert length(Enum.filter(otps, &is_nil(&1.used_at))) == 1
    end

    test "verify_otp/2 returns candidate and tenant for valid code", %{
      candidate: candidate,
      tenant: tenant
    } do
      {:ok, code} = CandidatePortal.generate_otp(candidate)

      assert {:ok, verified_candidate, verified_tenant} =
               CandidatePortal.verify_otp(candidate, code)

      assert verified_candidate.id == candidate.id
      assert verified_tenant.id == tenant.id
    end

    test "verify_otp/2 invalidates all pending codes on success", %{candidate: candidate} do
      {:ok, code} = CandidatePortal.generate_otp(candidate)
      {:ok, _, _} = CandidatePortal.verify_otp(candidate, code)

      otps =
        Repo.all(
          from o in Treby.CandidatePortal.CandidateOtp, where: o.candidate_id == ^candidate.id
        )

      assert Enum.all?(otps, &(not is_nil(&1.used_at)))
    end

    test "verify_otp/2 returns error for invalid code", %{candidate: candidate} do
      assert {:ok, _} = CandidatePortal.generate_otp(candidate)
      assert {:error, :invalid_or_expired} = CandidatePortal.verify_otp(candidate, "000000")
    end

    test "verify_otp/2 returns error for expired code", %{candidate: candidate} do
      {:ok, code} = CandidatePortal.generate_otp(candidate)
      expired = ~U[2020-01-01 00:00:00Z]

      Repo.update_all(
        from(o in Treby.CandidatePortal.CandidateOtp,
          where: o.candidate_id == ^candidate.id,
          update: [set: [expires_at: ^expired]]
        ),
        []
      )

      assert {:error, :invalid_or_expired} = CandidatePortal.verify_otp(candidate, code)
    end

    test "verify_otp/2 returns error after too many attempts", %{candidate: candidate} do
      {:ok, code} = CandidatePortal.generate_otp(candidate)

      Repo.update_all(
        from(o in Treby.CandidatePortal.CandidateOtp,
          where: o.candidate_id == ^candidate.id,
          update: [set: [attempts: 5]]
        ),
        []
      )

      assert {:error, :too_many_attempts} = CandidatePortal.verify_otp(candidate, code)
    end

    test "verify_otp/2 returns error for already used code", %{candidate: candidate} do
      {:ok, code} = CandidatePortal.generate_otp(candidate)
      assert {:ok, _, _} = CandidatePortal.verify_otp(candidate, code)
      assert {:error, :invalid_or_expired} = CandidatePortal.verify_otp(candidate, code)
    end

    test "record_failed_otp_attempt/2 increments attempts", %{candidate: candidate} do
      {:ok, code} = CandidatePortal.generate_otp(candidate)
      CandidatePortal.record_failed_otp_attempt(candidate, code)

      otp =
        Repo.one(
          from o in Treby.CandidatePortal.CandidateOtp, where: o.candidate_id == ^candidate.id
        )

      assert otp.attempts == 1
    end

    test "session_lifetime_hours/0 returns a positive value" do
      assert CandidatePortal.session_lifetime_hours() > 0
    end
  end

  describe "conversations" do
    setup do
      {tenant, candidate, application} = setup_tenant_and_job()
      {:ok, tenant: tenant, candidate: candidate, application: application}
    end

    test "create_conversation/1 creates a conversation", %{
      candidate: candidate,
      tenant: tenant,
      application: application
    } do
      attrs = %{
        candidate_id: candidate.id,
        tenant_id: tenant.id,
        subject: "Test Conversation",
        context: "application",
        application_id: application.id
      }

      assert {:ok, conversation} = CandidatePortal.create_conversation(attrs)
      assert conversation.subject == "Test Conversation"
      assert conversation.status == "open"
    end

    test "create_conversation/1 creates with system message", %{
      candidate: candidate,
      tenant: tenant,
      application: application
    } do
      {:ok, conversation} =
        CandidatePortal.create_conversation(
          %{
            candidate_id: candidate.id,
            tenant_id: tenant.id,
            subject: "Test Conversation",
            context: "application",
            application_id: application.id
          },
          "Welcome message"
        )

      messages = Repo.all(from m in Message, where: m.conversation_id == ^conversation.id)
      assert length(messages) == 1
      assert List.first(messages).body == "Welcome message"
      assert List.first(messages).sender_type == "system"
    end

    test "list_conversations_for_candidate/2 returns conversations", %{
      candidate: candidate,
      tenant: tenant,
      application: application
    } do
      CandidatePortal.create_conversation(%{
        candidate_id: candidate.id,
        tenant_id: tenant.id,
        subject: "Test Conversation",
        context: "application",
        application_id: application.id
      })

      conversations = CandidatePortal.list_conversations_for_candidate(candidate.id, tenant.id)
      assert length(conversations) == 1
    end

    test "get_conversation!/1 returns conversation", %{
      candidate: candidate,
      tenant: tenant,
      application: application
    } do
      {:ok, conversation} =
        CandidatePortal.create_conversation(%{
          candidate_id: candidate.id,
          tenant_id: tenant.id,
          subject: "Test Conversation",
          context: "application",
          application_id: application.id
        })

      found = CandidatePortal.get_conversation!(conversation.id)
      assert found.id == conversation.id
    end

    test "close_conversation/1 updates status", %{
      candidate: candidate,
      tenant: tenant,
      application: application
    } do
      {:ok, conversation} =
        CandidatePortal.create_conversation(%{
          candidate_id: candidate.id,
          tenant_id: tenant.id,
          subject: "Test Conversation",
          context: "application",
          application_id: application.id
        })

      {:ok, closed} = CandidatePortal.close_conversation(conversation)
      assert closed.status == "closed"
    end
  end

  describe "messages" do
    setup do
      {tenant, candidate, application} = setup_tenant_and_job()

      {:ok, conversation} =
        CandidatePortal.create_conversation(%{
          candidate_id: candidate.id,
          tenant_id: tenant.id,
          subject: "Test Conversation",
          context: "application",
          application_id: application.id
        })

      {:ok, tenant: tenant, candidate: candidate, conversation: conversation}
    end

    test "send_message/1 creates a message", %{conversation: conversation} do
      attrs = %{
        sender_type: "candidate",
        conversation_id: conversation.id,
        body: "Hello!",
        message_type: "text"
      }

      assert {:ok, message} = CandidatePortal.send_message(attrs)
      assert message.body == "Hello!"
      assert message.sender_type == "candidate"
    end

    test "send_message/1 updates conversation last_message_at", %{conversation: conversation} do
      CandidatePortal.send_message(%{
        sender_type: "candidate",
        conversation_id: conversation.id,
        body: "Hello!",
        message_type: "text"
      })

      updated = CandidatePortal.get_conversation!(conversation.id)
      assert updated.last_message_at != nil
    end

    test "send_message/1 with different message types", %{conversation: conversation} do
      {:ok, msg1} =
        CandidatePortal.send_message(%{
          sender_type: "system",
          conversation_id: conversation.id,
          body: "Status update",
          message_type: "status_update"
        })

      assert msg1.message_type == "status_update"

      {:ok, msg2} =
        CandidatePortal.send_message(%{
          sender_type: "recruiter",
          conversation_id: conversation.id,
          body: "Please provide references",
          message_type: "request_info"
        })

      assert msg2.message_type == "request_info"
    end
  end

  describe "notification preferences" do
    setup do
      {tenant, candidate, _application} = setup_tenant_and_job()
      {:ok, tenant: tenant, candidate: candidate}
    end

    test "get_notification_preferences/1 returns default preferences", %{candidate: candidate} do
      prefs = CandidatePortal.get_notification_preferences(candidate)
      assert prefs["new_message"] == true
      assert prefs["status_change"] == true
      assert prefs["interview_update"] == true
    end

    test "set_notification_preference/3 updates preference", %{candidate: candidate} do
      CandidatePortal.set_notification_preference(candidate, "new_message", false)

      updated = Repo.get!(Candidates.Candidate, candidate.id)
      prefs = CandidatePortal.get_notification_preferences(updated)
      assert prefs["new_message"] == false
    end

    test "set_notification_preference/3 preserves other preferences", %{candidate: candidate} do
      CandidatePortal.set_notification_preference(candidate, "new_message", false)

      updated = Repo.get!(Candidates.Candidate, candidate.id)
      prefs = CandidatePortal.get_notification_preferences(updated)
      assert prefs["new_message"] == false
      assert prefs["status_change"] == true
      assert prefs["interview_update"] == true
    end
  end
end
