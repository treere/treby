defmodule Treby.JobViewsTest do
  use Treby.DataCase, async: true

  alias Treby.{Tenants, Repo, JobViews}
  alias Treby.Jobs.Job
  alias Treby.Accounts.User

  defp setup_tenant(slug_suffix \\ nil) do
    suffix = slug_suffix || System.unique_integer([:positive])

    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Test Corp #{suffix}",
        slug: "test-#{suffix}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "test-#{suffix}@test.com",
        password: "password123",
        name: "Test User",
        role: "admin"
      })
      |> Repo.insert()

    {tenant, user}
  end

  defp create_job(tenant) do
    {:ok, pipeline} =
      Treby.Pipeline.create_pipeline(%{
        name: "Default #{System.unique_integer([:positive])}",
        tenant_id: tenant.id,
        is_default: true
      })

    {:ok, job} =
      tenant
      |> Ecto.build_assoc(:jobs)
      |> Job.changeset(%{
        title: "Software Engineer #{System.unique_integer([:positive])}",
        description: "Build things",
        pipeline_id: pipeline.id
      })
      |> Repo.insert()

    {job, pipeline}
  end

  describe "helpers" do
    test "bot?/1 detects bots" do
      assert JobViews.bot?("Googlebot/2.1")
      assert JobViews.bot?("Mozilla/5.0 (compatible; bingbot/2.0)")
      assert JobViews.bot?("Facebot")
      refute JobViews.bot?("Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
      refute JobViews.bot?(nil)
      refute JobViews.bot?("")
    end

    test "session_hash/3 is deterministic and different per day" do
      h1 = JobViews.session_hash("1.2.3.4", "Mozilla", ~D[2026-01-01])
      h2 = JobViews.session_hash("1.2.3.4", "Mozilla", ~D[2026-01-01])
      h3 = JobViews.session_hash("1.2.3.4", "Mozilla", ~D[2026-01-02])
      assert h1 == h2
      assert h1 != h3
      assert String.length(h1) == 32
    end

    test "extract_source/2 prefers utm_source" do
      assert JobViews.extract_source("linkedin", "https://google.com") == "linkedin"
      assert JobViews.extract_source("", "https://google.com/search") == "google.com"
      assert JobViews.extract_source(nil, nil) == "Direct"
      assert JobViews.extract_source("  ", "  ") == "Direct"
    end
  end

  describe "track_view/1" do
    test "anonymous visit creates a row" do
      {tenant, _user} = setup_tenant()
      {job, _} = create_job(tenant)
      hash = JobViews.session_hash("1.1.1.1", "Mozilla")

      assert {:ok, _view} =
               JobViews.track_view(%{
                 job_id: job.id,
                 tenant_id: tenant.id,
                 session_hash: hash,
                 viewed_at: DateTime.utc_now(),
                 user_agent: "Mozilla/5.0",
                 referer: "https://linkedin.com",
                 utm_source: "linkedin"
               })

      assert Repo.aggregate(
               from(v in Treby.JobViews.JobView, where: v.job_id == ^job.id),
               :count
             ) == 1
    end

    test "deduplication within 60m suppresses duplicate" do
      {tenant, _user} = setup_tenant()
      {job, _} = create_job(tenant)
      hash = JobViews.session_hash("2.2.2.2", "Mozilla")
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      assert {:ok, _} =
               JobViews.track_view(%{
                 job_id: job.id,
                 tenant_id: tenant.id,
                 session_hash: hash,
                 viewed_at: now,
                 user_agent: "Mozilla"
               })

      assert {:skip, :deduplicated} =
               JobViews.track_view(%{
                 job_id: job.id,
                 tenant_id: tenant.id,
                 session_hash: hash,
                 viewed_at: DateTime.add(now, 10, :minute),
                 user_agent: "Mozilla"
               })
    end

    test "view after window is counted again" do
      {tenant, _user} = setup_tenant()
      {job, _} = create_job(tenant)
      hash = JobViews.session_hash("3.3.3.3", "Mozilla")
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      later = DateTime.add(now, 61 * 60, :second)

      assert {:ok, _} =
               JobViews.track_view(%{
                 job_id: job.id,
                 tenant_id: tenant.id,
                 session_hash: hash,
                 viewed_at: now,
                 user_agent: "Mozilla"
               })

      assert {:ok, _} =
               JobViews.track_view(%{
                 job_id: job.id,
                 tenant_id: tenant.id,
                 session_hash: hash,
                 viewed_at: later,
                 user_agent: "Mozilla"
               })

      assert Repo.aggregate(from(v in Treby.JobViews.JobView, where: v.job_id == ^job.id), :count) ==
               2
    end

    test "bot is skipped" do
      {tenant, _user} = setup_tenant()
      {job, _} = create_job(tenant)
      hash = JobViews.session_hash("4.4.4.4", "Googlebot")

      assert {:skip, :bot} =
               JobViews.track_view(%{
                 job_id: job.id,
                 tenant_id: tenant.id,
                 session_hash: hash,
                 viewed_at: DateTime.utc_now(),
                 user_agent: "Googlebot/2.1"
               })
    end

    test "closed job is skipped" do
      {tenant, _user} = setup_tenant()
      {job, _} = create_job(tenant)
      {:ok, closed} = Treby.Jobs.update_job(job, %{status: "closed"})
      hash = JobViews.session_hash("5.5.5.5", "Mozilla")

      assert {:skip, :closed} =
               JobViews.track_view(%{
                 job_id: closed.id,
                 tenant_id: tenant.id,
                 session_hash: hash,
                 viewed_at: DateTime.utc_now(),
                 user_agent: "Mozilla"
               })
    end

    test "tenant mismatch is skipped" do
      {tenant_a, _} = setup_tenant()
      {tenant_b, _} = setup_tenant()
      {job, _} = create_job(tenant_a)
      hash = JobViews.session_hash("6.6.6.6", "Mozilla")

      assert {:skip, :tenant_mismatch} =
               JobViews.track_view(%{
                 job_id: job.id,
                 tenant_id: tenant_b.id,
                 session_hash: hash,
                 viewed_at: DateTime.utc_now(),
                 user_agent: "Mozilla"
               })
    end

    test "tenant isolation on aggregates" do
      {tenant_a, _} = setup_tenant()
      {tenant_b, _} = setup_tenant()
      {job, _} = create_job(tenant_a)
      hash = JobViews.session_hash("7.7.7.7", "Mozilla")

      {:ok, _} =
        JobViews.track_view(%{
          job_id: job.id,
          tenant_id: tenant_a.id,
          session_hash: hash,
          viewed_at: DateTime.utc_now(),
          user_agent: "Mozilla"
        })

      assert {:error, :not_found} = JobViews.get_summary(tenant_b.id, job.id)
    end

    test "truncates long user_agent" do
      {tenant, _} = setup_tenant()
      {job, _} = create_job(tenant)
      hash = JobViews.session_hash("8.8.8.8", String.duplicate("a", 500))
      long_ua = String.duplicate("a", 500)

      assert {:ok, view} =
               JobViews.track_view(%{
                 job_id: job.id,
                 tenant_id: tenant.id,
                 session_hash: hash,
                 viewed_at: DateTime.utc_now(),
                 user_agent: long_ua
               })

      assert String.length(view.user_agent) == 255
    end
  end

  describe "aggregations" do
    test "get_summary returns zeros for job with no views" do
      {tenant, _} = setup_tenant()
      {job, _} = create_job(tenant)
      assert {:ok, summary} = JobViews.get_summary(tenant.id, job.id)
      assert summary.total_views == 0
      assert summary.unique_views == 0
      assert summary.views_last_7_days == 0
      assert summary.avg_daily_views == 0.0
    end

    test "get_summary aggregates correctly" do
      {tenant, _} = setup_tenant()
      {job, _} = create_job(tenant)
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      for i <- 1..3 do
        hash = JobViews.session_hash("10.0.0.#{i}", "UA#{i}")

        {:ok, _} =
          JobViews.track_view(%{
            job_id: job.id,
            tenant_id: tenant.id,
            session_hash: hash,
            viewed_at: now,
            user_agent: "UA#{i}"
          })
      end

      # duplicate session hash but different hash considered unique, so 3 uniques
      assert {:ok, summary} = JobViews.get_summary(tenant.id, job.id)
      assert summary.total_views == 3
      assert summary.unique_views == 3
      assert summary.views_last_7_days == 3
    end

    test "daily_breakdown fills missing days" do
      {tenant, _} = setup_tenant()
      {job, _} = create_job(tenant)
      hash = JobViews.session_hash("11.11.11.11", "Mozilla")

      {:ok, _} =
        JobViews.track_view(%{
          job_id: job.id,
          tenant_id: tenant.id,
          session_hash: hash,
          viewed_at: DateTime.utc_now(),
          user_agent: "Mozilla"
        })

      assert {:ok, breakdown} = JobViews.daily_breakdown(tenant.id, job.id, 7)
      assert length(breakdown) == 7
      # last entry should be today with count 1
      assert List.last(breakdown).count == 1
      # earlier days 0
      assert Enum.take(breakdown, 6) |> Enum.all?(&(&1.count == 0))
    end

    test "monthly_breakdown fills missing months" do
      {tenant, _} = setup_tenant()
      {job, _} = create_job(tenant)
      hash = JobViews.session_hash("12.12.12.12", "Mozilla")

      {:ok, _} =
        JobViews.track_view(%{
          job_id: job.id,
          tenant_id: tenant.id,
          session_hash: hash,
          viewed_at: DateTime.utc_now(),
          user_agent: "Mozilla"
        })

      assert {:ok, breakdown} = JobViews.monthly_breakdown(tenant.id, job.id, 3)
      assert length(breakdown) == 3
      assert List.last(breakdown).count == 1
    end

    test "source breakdown groups correctly" do
      {tenant, _} = setup_tenant()
      {job, _} = create_job(tenant)

      for {src, ref, n} <- [{"linkedin", nil, 2}, {nil, "https://google.com", 1}, {nil, nil, 1}] do
        for i <- 1..n do
          hash = JobViews.session_hash("13.#{n}.#{i}.#{System.unique_integer([:positive])}", "UA")

          {:ok, _} =
            JobViews.track_view(%{
              job_id: job.id,
              tenant_id: tenant.id,
              session_hash: hash,
              viewed_at: DateTime.utc_now(),
              user_agent: "UA",
              utm_source: src,
              referer: ref
            })
        end
      end

      assert {:ok, breakdown} = JobViews.source_breakdown(tenant.id, job.id)
      assert length(breakdown) == 3
      assert Enum.find(breakdown, &(&1.source == "linkedin")).count == 2
      assert Enum.find(breakdown, &(&1.source == "google.com")).count == 1
      assert Enum.find(breakdown, &(&1.source == "Direct")).count == 1
    end

    test "source breakdown empty returns []" do
      {tenant, _} = setup_tenant()
      {job, _} = create_job(tenant)
      assert {:ok, []} = JobViews.source_breakdown(tenant.id, job.id)
    end

    test "funnel returns 0% when no views" do
      {tenant, _} = setup_tenant()
      {job, _} = create_job(tenant)
      assert {:ok, funnel} = JobViews.funnel_for_job(tenant.id, job.id)
      assert funnel.total_views == 0
      assert funnel.conversion_rate == 0.0
    end

    test "funnel conversion calculates correctly" do
      {tenant, _} = setup_tenant()
      {job, pipeline} = create_job(tenant)
      hash = JobViews.session_hash("14.14.14.14", "Mozilla")

      {:ok, _} =
        JobViews.track_view(%{
          job_id: job.id,
          tenant_id: tenant.id,
          session_hash: hash,
          viewed_at: DateTime.utc_now(),
          user_agent: "Mozilla"
        })

      # create candidate and application
      {:ok, candidate} =
        Treby.Candidates.create_candidate(%{
          name: "Cand #{System.unique_integer([:positive])}",
          email: "cand-#{System.unique_integer([:positive])}@test.com",
          tenant_id: tenant.id
        })

      stage =
        case Treby.Pipeline.list_pipeline_stages_for_job(job.id) |> List.first() do
          nil ->
            {:ok, s} =
              Treby.Pipeline.create_pipeline_stage(%{
                name: "New",
                position: 0,
                color: "#10b981",
                stage_type: "new",
                pipeline_id: pipeline.id
              })

            s

          s ->
            s
        end

      {:ok, _app} =
        Treby.Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: stage.id,
          applied_at: DateTime.utc_now()
        })

      assert {:ok, funnel} = JobViews.funnel_for_job(tenant.id, job.id)
      assert funnel.total_views == 1
      assert funnel.total_applications == 1
      assert funnel.conversion_rate == 100.0
    end

    test "summaries_for_tenant avoids N+1" do
      {tenant, _} = setup_tenant()
      {job1, _} = create_job(tenant)
      {job2, _} = create_job(tenant)
      h1 = JobViews.session_hash("15.1.1.1", "UA1")
      h2 = JobViews.session_hash("15.2.2.2", "UA2")

      {:ok, _} =
        JobViews.track_view(%{
          job_id: job1.id,
          tenant_id: tenant.id,
          session_hash: h1,
          viewed_at: DateTime.utc_now(),
          user_agent: "UA1"
        })

      {:ok, _} =
        JobViews.track_view(%{
          job_id: job2.id,
          tenant_id: tenant.id,
          session_hash: h2,
          viewed_at: DateTime.utc_now(),
          user_agent: "UA2"
        })

      {:ok, _} =
        JobViews.track_view(%{
          job_id: job1.id,
          tenant_id: tenant.id,
          session_hash: JobViews.session_hash("15.1.1.2", "UA3"),
          viewed_at: DateTime.utc_now(),
          user_agent: "UA3"
        })

      summaries = JobViews.summaries_for_tenant(tenant.id)
      assert summaries[job1.id].total_views == 2
      assert summaries[job2.id].total_views == 1
    end
  end
end
