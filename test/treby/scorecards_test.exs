defmodule Treby.ScorecardsTest do
  use Treby.DataCase, async: true

  alias Treby.Interviews.EventExaminer
  alias Treby.Interviews.InterviewEvent
  alias Treby.Pipeline.PipelineStage
  alias Treby.Scorecards

  setup do
    tenant =
      Repo.insert!(%Treby.Tenants.Tenant{
        name: "Scorecards Test",
        slug: "scorecards-#{System.unique_integer([:positive])}"
      })

    Treby.Pipeline.create_default_pipeline_stages(tenant)

    user =
      Repo.insert!(%Treby.Accounts.User{
        name: "Examiner",
        email: "examiner-#{System.unique_integer([:positive])}@example.com",
        password_hash: Bcrypt.hash_pwd_salt("password123456"),
        tenant_id: tenant.id
      })

    job =
      Repo.insert!(%Treby.Jobs.Job{
        title: "Test Job",
        description: "A test job",
        tenant_id: tenant.id,
        pipeline_id: Treby.Pipeline.default_pipeline_id(tenant.id)
      })

    candidate =
      Repo.insert!(%Treby.Candidates.Candidate{
        name: "Test Candidate",
        email: "candidate-#{System.unique_integer([:positive])}@example.com",
        tenant_id: tenant.id
      })

    stage =
      Repo.one!(
        from s in PipelineStage,
          where: s.stage_type == "interview" and s.pipeline_id == ^job.pipeline_id
      )

    application =
      Repo.insert!(%Treby.Pipeline.Application{
        job_id: job.id,
        candidate_id: candidate.id,
        pipeline_stage_id: stage.id,
        tenant_id: tenant.id,
        applied_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    event =
      Repo.insert!(%InterviewEvent{
        start_at_utc: now,
        end_at_utc: DateTime.add(now, 1800, :second),
        duration_minutes: 30,
        status: "completed",
        application_id: application.id,
        tenant_id: tenant.id
      })

    Repo.insert!(%EventExaminer{interview_event_id: event.id, user_id: user.id})

    %{tenant: tenant, user: user, event: event, candidate: candidate}
  end

  test "aggregates only numeric criteria and keeps averages as floats", ctx do
    {:ok, _} =
      Scorecards.submit_scorecard(ctx.event.id, ctx.user.id, %{
        "scores" => %{"Technical skills" => 5, "Culture fit" => "yes"},
        "recommendation" => "hire",
        "notes" => "Great",
        "tenant_id" => ctx.tenant.id
      })

    aggregate = Scorecards.compute_aggregate_scores(ctx.candidate.id)

    assert aggregate.avg_scores["Technical skills"] == 5.0
    refute Map.has_key?(aggregate.avg_scores, "Culture fit")
    assert Enum.all?(Map.values(aggregate.avg_scores), &is_float/1)
  end

  test "returns no average for criteria scored only non-numerically", ctx do
    {:ok, _} =
      Scorecards.submit_scorecard(ctx.event.id, ctx.user.id, %{
        "scores" => %{"Culture fit" => "maybe"},
        "recommendation" => "lean_hire",
        "notes" => "Ok",
        "tenant_id" => ctx.tenant.id
      })

    aggregate = Scorecards.compute_aggregate_scores(ctx.candidate.id)

    assert aggregate.avg_scores == %{}
    assert aggregate.total_scorecards == 1
  end
end
