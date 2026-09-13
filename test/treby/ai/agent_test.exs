defmodule Treby.AI.AgentTest do
  use Treby.DataCase, async: false

  alias Treby.AI.{Agent, Conversations}
  alias Treby.{Audit, Repo, Tenants}
  alias Treby.Accounts.User
  alias Treby.Jobs.Job

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "AI Agent #{System.unique_integer([:positive])}",
        slug: "ai-agent-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "ai-agent-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "AI Agent User",
        role: "admin"
      })
      |> Repo.insert()

    {tenant, user}
  end

  defp pending_run(tenant, user, tool, args) do
    conversation = Conversations.get_or_create_conversation(tenant.id, user.id)

    {:ok, message} =
      Conversations.create_message(conversation, %{role: "assistant", content: "confirm?"})

    {:ok, run} =
      Conversations.create_tool_run(message, %{tool: tool, args: args, status: "pending_confirm"})

    run
  end

  test "confirm executes the tool and logs one audit event with via: ai" do
    {tenant, user} = setup_tenant()

    job =
      tenant
      |> Ecto.build_assoc(:jobs)
      |> Job.changeset(%{title: "Delete me", description: "d"})
      |> Repo.insert!()

    conversation = Conversations.get_or_create_conversation(tenant.id, user.id)

    {:ok, _} =
      Conversations.create_message(conversation, %{
        role: "user",
        content: "per favore elimina il job"
      })

    {:ok, message} =
      Conversations.create_message(conversation, %{role: "assistant", content: "confirm?"})

    {:ok, run} =
      Conversations.create_tool_run(message, %{
        tool: "delete_job",
        args: %{"job_id" => job.id},
        status: "pending_confirm"
      })

    assert {:ok, _result} = Agent.confirm_tool_run(run, %{tenant_id: tenant.id, user: user})
    assert Repo.get(Job, job.id) == nil

    {events, _} = Audit.list_events(tenant.id)
    ai_events = Enum.filter(events, &(&1.action == "ai.tool.executed"))

    assert length(ai_events) == 1
    event = hd(ai_events)
    assert event.metadata["via"] == "ai"
    assert event.metadata["prompt_excerpt"] == "per favore elimina il job"
    assert event.metadata["tool"] == "delete_job"
    assert event.actor_id == user.id
  end

  test "pending runs are not audited" do
    {tenant, user} = setup_tenant()

    job =
      tenant
      |> Ecto.build_assoc(:jobs)
      |> Job.changeset(%{title: "Still here", description: "d"})
      |> Repo.insert!()

    _run = pending_run(tenant, user, "delete_job", %{"job_id" => job.id})

    {events, _} = Audit.list_events(tenant.id)
    assert Enum.filter(events, &(&1.action == "ai.tool.executed")) == []
  end

  test "reject marks the run rejected and does not mutate" do
    {tenant, user} = setup_tenant()

    job =
      tenant
      |> Ecto.build_assoc(:jobs)
      |> Job.changeset(%{title: "Keep me", description: "d"})
      |> Repo.insert!()

    run = pending_run(tenant, user, "delete_job", %{"job_id" => job.id})

    assert {:ok, rejected} = Agent.reject_tool_run(run)
    assert rejected.status == "rejected"
    assert Repo.get(Job, job.id)

    assert Conversations.list_pending_tool_runs(
             Repo.get!(Treby.AI.Conversation, run_message_conv(run))
           ) == []
  end

  defp run_message_conv(run) do
    Repo.get!(Treby.AI.Message, run.message_id).conversation_id
  end
end
