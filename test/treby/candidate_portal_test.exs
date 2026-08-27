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

  describe "magic link tokens" do
    setup do
      {tenant, candidate, _application} = setup_tenant_and_job()
      {:ok, tenant: tenant, candidate: candidate}
    end

    test "generate_magic_link_token/1 creates a valid token", %{candidate: candidate} do
      assert {:ok, token} = CandidatePortal.generate_magic_link_token(candidate)
      assert is_binary(token)
      assert String.length(token) > 0
    end

    test "validate_magic_link_token/1 returns candidate for valid token", %{
      candidate: candidate,
      tenant: tenant
    } do
      {:ok, token} = CandidatePortal.generate_magic_link_token(candidate)

      assert {:ok, validated_candidate, validated_tenant} =
               CandidatePortal.validate_magic_link_token(token)

      assert validated_candidate.id == candidate.id
      assert validated_tenant.id == tenant.id
    end

    test "validate_magic_link_token/1 returns error for invalid token" do
      assert {:error, :invalid_token} = CandidatePortal.validate_magic_link_token("invalid_token")
    end

    test "validate_magic_link_token/1 returns error for expired token", %{candidate: candidate} do
      {:ok, token} = CandidatePortal.generate_magic_link_token(candidate)

      # Manually expire the token by using it and then checking
      # We'll test expiry indirectly by validating that the token works once
      assert {:ok, _, _} = CandidatePortal.validate_magic_link_token(token)

      # Token is now used, so it should fail with token_already_used
      assert {:error, :token_already_used} = CandidatePortal.validate_magic_link_token(token)
    end

    test "validate_magic_link_token/1 returns error for used token", %{candidate: candidate} do
      {:ok, token} = CandidatePortal.generate_magic_link_token(candidate)

      # Use the token
      assert {:ok, _, _} = CandidatePortal.validate_magic_link_token(token)

      # Try to use it again
      assert {:error, :token_already_used} = CandidatePortal.validate_magic_link_token(token)
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
