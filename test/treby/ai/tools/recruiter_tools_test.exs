defmodule Treby.AI.Tools.RecruiterToolsTest do
  use Treby.DataCase, async: false

  alias Treby.AI.{Agent, Conversations, Tools}
  alias Treby.{Repo, Jobs, Candidates, Pipeline, Tenants}
  alias Treby.Accounts.User

  setup do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Recruiter Tools #{System.unique_integer([:positive])}",
        slug: "rec-tools-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "rec-tools-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Recruiter Tools User",
        role: "admin"
      })
      |> Repo.insert()

    {:ok, _} =
      Treby.Memberships.create_membership(%{
        user_id: user.id,
        tenant_id: tenant.id,
        role: "admin"
      })

    {:ok, job} =
      Jobs.create_job(%{
        tenant_id: tenant.id,
        actor_id: user.id,
        title: "Engineer",
        description: "Build"
      })

    {:ok, candidate} = Candidates.create_or_find(tenant.id, %{name: "Jane", email: "jane@x.z"})

    pipeline_id = Pipeline.default_pipeline_id(tenant.id)

    {:ok, stage_a} =
      Pipeline.create_pipeline_stage(
        %{pipeline_id: pipeline_id, name: "A", stage_type: "new"},
        user
      )

    {:ok, stage_b} =
      Pipeline.create_pipeline_stage(
        %{pipeline_id: pipeline_id, name: "B", stage_type: "screening"},
        user
      )

    {:ok, application} =
      Pipeline.create_application(
        %{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: stage_a.id,
          applied_at: DateTime.utc_now() |> DateTime.to_iso8601()
        },
        []
      )

    ctx = %{
      tenant_id: tenant.id,
      user_id: user.id,
      user: user,
      session_token: "tok-rec-tools"
    }

    {:ok,
     tenant: tenant,
     user: user,
     job: job,
     candidate: candidate,
     stage_a: stage_a,
     stage_b: stage_b,
     application: application,
     ctx: ctx}
  end

  test "create_candidate writes via the business module", %{ctx: ctx} do
    assert {:ok, %{"id" => id, "email" => "new@x.z"}} =
             Tools.CreateCandidate.run(%{"name" => "New", "email" => "new@x.z"}, ctx)

    assert %{email: "new@x.z"} = Candidates.get_candidate(ctx.tenant_id, id)
  end

  test "list_candidates returns the workspace candidates", %{ctx: ctx, candidate: candidate} do
    assert {:ok, list} = Tools.ListCandidates.run(%{}, ctx)
    ids = Enum.map(list, & &1["id"])
    assert candidate.id in ids
  end

  test "get_candidate returns the entity", %{ctx: ctx, candidate: candidate} do
    assert {:ok, found} = Tools.GetCandidate.run(%{"id" => candidate.id}, ctx)
    assert found.id == candidate.id
  end

  test "move_application changes the stage", %{
    ctx: ctx,
    application: application,
    stage_b: stage_b
  } do
    assert {:ok, %{"stage_id" => sid}} =
             Tools.MoveApplication.run(%{"id" => application.id, "stage_id" => stage_b.id}, ctx)

    assert sid == stage_b.id
    assert Pipeline.get_application(application.id).pipeline_stage_id == stage_b.id
  end

  test "add_note attaches a note to the application", %{ctx: ctx, application: application} do
    assert {:ok, %{"id" => note_id}} =
             Tools.AddNote.run(
               %{"application_id" => application.id, "content" => "Strong yes"},
               ctx
             )

    assert %{content: "Strong yes"} = Repo.get(Treby.Notes.Note, note_id)
  end

  test "destructive flags are set for writers and clear for readers" do
    assert Tools.CreateCandidate.destructive?()
    assert Tools.UpdateCandidate.destructive?()
    assert Tools.MoveApplication.destructive?()
    assert Tools.AddNote.destructive?()
    refute Tools.ListCandidates.destructive?()
    refute Tools.GetCandidate.destructive?()
  end

  test "confirm_tool_run executes a destructive tool only after explicit confirmation", %{
    ctx: ctx
  } do
    conversation =
      Conversations.get_or_create_conversation(ctx.tenant_id, ctx.user_id, "tok-confirm")

    {:ok, message} =
      Conversations.create_message(conversation, %{role: "assistant", content: "x"})

    {:ok, run} =
      Conversations.create_tool_run(message, %{
        tool: "create_candidate",
        args: %{"name" => "Confirmed", "email" => "confirmed@x.z"},
        status: "pending_confirm"
      })

    assert {:ok, %{"email" => "confirmed@x.z"}} = Agent.confirm_tool_run(run, ctx)
    assert Repo.get_by(Treby.Candidates.Candidate, email: "confirmed@x.z")
  end
end
