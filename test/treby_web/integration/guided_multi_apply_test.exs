defmodule TrebyWeb.GuidedMultiApplyTest do
  use TrebyWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias Treby.{Tenants, Repo, Pipeline}
  alias Treby.Candidates.Candidate
  alias Treby.Jobs.Job

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{name: "Multi", slug: "multi-#{System.unique_integer([:positive])}"})

    if is_nil(Pipeline.default_pipeline_id(tenant.id)),
      do: Treby.Pipeline.create_default_pipeline_stages(tenant)

    tenant
  end

  test "prefilled apply form for authenticated candidate", %{conn: conn} do
    tenant = setup_tenant()

    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidate.changeset(%{
        name: "Prefill Cand",
        email: "prefill-#{System.unique_integer([:positive])}@test.com",
        phone: "555-1234"
      })
      |> Repo.insert()

    {:ok, job} =
      tenant
      |> Ecto.build_assoc(:jobs)
      |> Job.changeset(%{title: "Prefill Job", description: "desc"})
      |> Repo.insert()

    expires = DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.to_unix()

    conn =
      init_test_session(conn, %{
        "candidate_id" => candidate.id,
        "candidate_tenant_id" => tenant.id,
        "candidate_expires_at" => expires
      })

    {:ok, view, html} = live(conn, ~p"/#{tenant.slug}/careers/#{job.id}/apply")
    assert html =~ candidate.name
    assert html =~ candidate.email
    assert html =~ "Prefilled from your portal profile"
    # anonymous should see empty
    {:ok, view2, html2} = live(build_conn(), ~p"/#{tenant.slug}/careers/#{job.id}/apply")
    refute html2 =~ "Prefilled from your portal profile"
  end

  test "applied badge on list and swapped CTA on detail", %{conn: conn} do
    tenant = setup_tenant()

    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidate.changeset(%{
        name: "Badge Cand",
        email: "badge-#{System.unique_integer([:positive])}@test.com"
      })
      |> Repo.insert()

    {:ok, job} =
      tenant
      |> Ecto.build_assoc(:jobs)
      |> Job.changeset(%{title: "Badge Job", description: "desc"})
      |> Repo.insert()

    pipeline_id = Pipeline.default_pipeline_id(tenant.id)
    [first | _] = Pipeline.list_pipeline_stages(pipeline_id)

    {:ok, _} =
      Pipeline.create_application(%{
        "tenant_id" => tenant.id,
        "job_id" => job.id,
        "candidate_id" => candidate.id,
        "pipeline_stage_id" => first.id,
        "applied_at" => DateTime.utc_now()
      })

    expires = DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.to_unix()

    conn =
      init_test_session(conn, %{
        "candidate_id" => candidate.id,
        "candidate_tenant_id" => tenant.id,
        "candidate_expires_at" => expires
      })

    {:ok, _view, html} = live(conn, ~p"/#{tenant.slug}/careers")
    assert html =~ "Applied ✓"
    {:ok, _view2, html2} = live(conn, ~p"/#{tenant.slug}/careers/#{job.id}")
    assert html2 =~ "Already applied"
    refute html2 =~ "Apply Now"
  end
end
