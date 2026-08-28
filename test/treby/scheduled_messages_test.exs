defmodule Treby.ScheduledMessagesTest do
  use Treby.DataCase

  alias Treby.ScheduledMessages
  alias Treby.ScheduledMessages.ScheduledMessage
  alias Treby.{Tenants, Candidates, Pipeline, Repo}
  alias Treby.Jobs.Job
  alias Treby.CandidatePortal

  defp setup_conversation do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Sched Msg Corp",
        slug: "sched-msg-#{System.unique_integer([:positive])}"
      })

    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidates.Candidate.changeset(%{
        name: "Sched Candidate",
        email: "sched-#{System.unique_integer([:positive])}@example.com"
      })
      |> Repo.insert()

    {:ok, job} =
      tenant
      |> Ecto.build_assoc(:jobs)
      |> Job.changeset(%{
        title: "Engineer",
        description: "Test",
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

    {:ok, conversation} =
      CandidatePortal.create_conversation(%{
        candidate_id: candidate.id,
        tenant_id: tenant.id,
        application_id: application.id,
        subject: "Hello",
        context: "general"
      })

    {tenant, conversation}
  end

  test "create_scheduled_message/1 schedules delivery" do
    {tenant, conversation} = setup_conversation()

    {:ok, scheduled} =
      ScheduledMessages.create_scheduled_message(%{
        tenant_id: tenant.id,
        sender_type: "recruiter",
        conversation_id: conversation.id,
        body: "Hello there",
        message_type: "text",
        send_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      })

    assert scheduled.body == "Hello there"

    conversation =
      Repo.preload(Repo.get!(CandidatePortal.Conversation, conversation.id), :messages)

    assert length(conversation.messages) == 1
    assert List.first(conversation.messages).body == "Hello there"
  end

  test "deliver_now/1 posts the message and marks it sent" do
    {tenant, conversation} = setup_conversation()
    scheduled = insert_scheduled(tenant, conversation)

    {:ok, _} = ScheduledMessages.deliver_now(scheduled)

    updated = Repo.get!(ScheduledMessage, scheduled.id)
    assert updated.status == "sent"

    conversation =
      Repo.preload(Repo.get!(CandidatePortal.Conversation, conversation.id), :messages)

    assert length(conversation.messages) == 1
    assert List.first(conversation.messages).body == "Hello there"
  end

  test "cancel/1 sets status to cancelled" do
    {tenant, conversation} = setup_conversation()
    scheduled = insert_scheduled(tenant, conversation)

    {:ok, cancelled} = ScheduledMessages.cancel(scheduled)
    assert cancelled.status == "cancelled"
  end

  test "edit/2 updates body and reschedules" do
    {tenant, conversation} = setup_conversation()
    scheduled = insert_scheduled(tenant, conversation)

    new_send_at = DateTime.utc_now() |> DateTime.add(7200, :second) |> DateTime.truncate(:second)

    {:ok, updated} = ScheduledMessages.edit(scheduled, %{body: "Edited", send_at: new_send_at})
    assert updated.body == "Edited"
    assert DateTime.compare(updated.send_at, new_send_at) == :eq
  end

  test "retry_failed/1 re-attempts delivery" do
    {tenant, conversation} = setup_conversation()
    scheduled = insert_scheduled(tenant, conversation)

    {:ok, failed} =
      ScheduledMessages.record_failure(scheduled, "boom", true)

    assert failed.status == "failed"

    {:ok, _} = ScheduledMessages.retry_failed(failed)
    updated = Repo.get!(ScheduledMessage, scheduled.id)
    assert updated.status == "sent"
    assert updated.error_reason == nil
  end

  test "list_failed/1 returns failed messages for the tenant" do
    {tenant, conversation} = setup_conversation()
    scheduled = insert_scheduled(tenant, conversation)

    ScheduledMessages.record_failure(scheduled, "boom", true)

    failed = ScheduledMessages.list_failed(tenant.id)
    assert length(failed) == 1
  end

  defp insert_scheduled(tenant, conversation) do
    %ScheduledMessage{}
    |> ScheduledMessage.changeset(%{
      tenant_id: tenant.id,
      sender_type: "recruiter",
      conversation_id: conversation.id,
      body: "Hello there",
      message_type: "text",
      send_at: DateTime.add(DateTime.utc_now(), 3600, :second),
      status: "scheduled"
    })
    |> Repo.insert!()
  end
end
