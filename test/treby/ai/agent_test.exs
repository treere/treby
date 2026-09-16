defmodule Treby.AI.AgentTest do
  use Treby.DataCase, async: false

  alias Treby.AI.{Agent, Conversations}
  alias Treby.{Audit, Repo, Tenants}
  alias Treby.Accounts.User
  alias Treby.Jobs.Job
  alias Treby.Test.AiFormFillServer
  alias Treby.Test.AiJsonServer
  alias Treby.Test.AiSSE.Server, as: AiSSEServer

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

  test "streams chunks before completion and persists one assistant message" do
    {tenant, user} = setup_tenant()

    {server_pid, port} = AiSSEServer.start()
    on_exit(fn -> Process.exit(server_pid, :shutdown) end)

    previous_ai = Application.get_env(:treby, :ai, [])
    ai_config = [base_url: "http://127.0.0.1:#{port}/v1", api_key: "test", model: "test-model"]

    Application.put_env(:treby, :ai, Keyword.merge(previous_ai, ai_config))

    on_exit(fn ->
      Application.put_env(:treby, :ai, previous_ai)
    end)

    Phoenix.PubSub.subscribe(Treby.PubSub, Conversations.topic(tenant.id, user.id))

    ctx = %{
      tenant_id: tenant.id,
      user_id: user.id,
      session_token: "tok-stream",
      system_prompt: "You are a terse test assistant."
    }

    assert {:ok, :complete} = Agent.chat(ctx, "ciao")

    user_id = user.id
    assert_receive {:ai_stream, ^user_id, streamed}, 5_000
    assert streamed == "Ciao mondo"

    remaining = Process.info(self(), :messages) |> elem(1)

    assert {:ai_updated, ^user_id} = List.last(remaining)
    # The throttled tail chunk must be flushed before the completion broadcast,
    # so no stream event may arrive after the final ai_updated.
    assert Enum.all?(remaining, &match?({:ai_updated, _}, &1))

    conversation = Conversations.resolve_conversation(tenant.id, user.id, "tok-stream")
    messages = Conversations.list_messages(conversation)

    assert [%{role: "assistant", content: "Ciao mondo"}] =
             Enum.filter(messages, &(&1.role == "assistant"))

    assert [%{role: "user", content: "ciao"}] = Enum.filter(messages, &(&1.role == "user"))
  end

  test "propose_form_fill is applied to the host form without confirmation" do
    {tenant, user} = setup_tenant()

    {server_pid, port} = AiFormFillServer.start()
    on_exit(fn -> Process.exit(server_pid, :shutdown) end)

    previous_ai = Application.get_env(:treby, :ai, [])

    Application.put_env(
      :treby,
      :ai,
      Keyword.merge(previous_ai,
        base_url: "http://127.0.0.1:#{port}/v1",
        api_key: "test",
        model: "test-model"
      )
    )

    on_exit(fn -> Application.put_env(:treby, :ai, previous_ai) end)

    ctx = %{
      tenant_id: tenant.id,
      user_id: user.id,
      session_token: "tok-formfill",
      host_pid: self(),
      form_assign_key: :form,
      system_prompt: "You fill forms."
    }

    assert {:ok, :complete} = Agent.chat(ctx, "fill the job form")

    assert_receive {:ai_apply_form, %{assign_key: :form, values: %{"title" => "X"}}}, 5_000

    conversation = Conversations.resolve_conversation(tenant.id, user.id, "tok-formfill")
    assert Conversations.list_pending_tool_runs(conversation) == []
  end

  test "outbound controller passes an in-domain reply through unchanged" do
    {tenant, user} = setup_tenant()

    {server_pid, port} = AiJsonServer.start("All good")
    on_exit(fn -> Process.exit(server_pid, :shutdown) end)

    previous_ai = Application.get_env(:treby, :ai, [])

    Application.put_env(
      :treby,
      :ai,
      Keyword.merge(previous_ai,
        base_url: "http://127.0.0.1:#{port}/v1",
        api_key: "test",
        model: "test-model"
      )
    )

    on_exit(fn -> Application.put_env(:treby, :ai, previous_ai) end)

    ctx = %{
      tenant_id: tenant.id,
      user_id: user.id,
      session_token: "tok-ctl",
      system_prompt: "You are a terse test assistant."
    }

    assert {:ok, :complete} = Agent.chat(ctx, "hi")

    conversation = Conversations.resolve_conversation(tenant.id, user.id, "tok-ctl")

    assert [%{role: "assistant", content: "All good"}] =
             Enum.filter(Conversations.list_messages(conversation), &(&1.role == "assistant"))
  end
end
