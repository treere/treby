defmodule TrebyWeb.CandidatePortalSecurityTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo, Pipeline}
  alias Treby.Candidates.Candidate
  alias Treby.Jobs.Job

  defp setup_tenant(slug) do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Tenant #{slug}",
        slug: "#{slug}-#{System.unique_integer([:positive])}"
      })

    tenant
  end

  defp setup_candidate(tenant, email_suffix \\ nil) do
    email = "cand-#{email_suffix || System.unique_integer([:positive])}@test.com"

    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidate.changeset(%{name: "Cand #{email_suffix}", email: email})
      |> Repo.insert()

    candidate
  end

  defp setup_job(tenant) do
    {:ok, job} =
      tenant
      |> Ecto.build_assoc(:jobs)
      |> Job.changeset(%{
        title: "Security Job #{System.unique_integer([:positive])}",
        description: "desc"
      })
      |> Repo.insert()

    job
  end

  defp setup_application(tenant, candidate, job) do
    pipeline_id =
      Pipeline.default_pipeline_id(tenant.id) ||
        Treby.Pipeline.create_default_pipeline_stages(tenant).id

    # ensure pipeline exists
    pipeline_id = Pipeline.default_pipeline_id(tenant.id)
    [first_stage | _] = Pipeline.list_pipeline_stages(pipeline_id)

    {:ok, app} =
      Pipeline.create_application(%{
        "tenant_id" => tenant.id,
        "job_id" => job.id,
        "candidate_id" => candidate.id,
        "pipeline_stage_id" => first_stage.id,
        "applied_at" => DateTime.utc_now()
      })

    app
  end

  defp candidate_session(conn, tenant, candidate) do
    expires = DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.to_unix()

    init_test_session(conn, %{
      "candidate_id" => candidate.id,
      "candidate_tenant_id" => tenant.id,
      "candidate_expires_at" => expires
    })
  end

  describe "IDOR protection" do
    test "candidate cannot view another candidate's application", %{conn: conn} do
      tenant = setup_tenant("idor")
      # ensure pipeline stages exist
      if is_nil(Pipeline.default_pipeline_id(tenant.id)) do
        Treby.Pipeline.create_default_pipeline_stages(tenant)
      end

      candidate_a = setup_candidate(tenant, "a")
      candidate_b = setup_candidate(tenant, "b")
      job = setup_job(tenant)
      app_b = setup_application(tenant, candidate_b, job)

      conn = candidate_session(conn, tenant, candidate_a)

      {:ok, view, _html} = live(conn, ~p"/#{tenant.slug}/portal")

      # Direct event injection bypassing UI: attacker guesses UUID
      html = render_click(view, "select_application", %{"id" => app_b.id})

      # Should not show B's job title, should show error flash
      refute html =~ job.title
      assert html =~ "Application not found" or html =~ "Your Applications"
    end

    test "cross-tenant IDOR blocked", %{conn: conn} do
      tenant_a = setup_tenant("cross-a")
      tenant_b = setup_tenant("cross-b")

      for t <- [tenant_a, tenant_b] do
        if is_nil(Pipeline.default_pipeline_id(t.id)),
          do: Treby.Pipeline.create_default_pipeline_stages(t)
      end

      candidate_a = setup_candidate(tenant_a, "cross-a")
      candidate_b = setup_candidate(tenant_b, "cross-b")
      job_b = setup_job(tenant_b)
      app_b = setup_application(tenant_b, candidate_b, job_b)

      conn = candidate_session(conn, tenant_a, candidate_a)
      {:ok, view, _html} = live(conn, ~p"/#{tenant_a.slug}/portal")

      html = render_click(view, "select_application", %{"id" => app_b.id})
      refute html =~ job_b.title
    end
  end

  describe "tenant slug mismatch" do
    test "redirects to own portal when visiting wrong tenant slug", %{conn: conn} do
      tenant_a = setup_tenant("mismatch-a")
      tenant_b = setup_tenant("mismatch-b")
      # ensure candidate exists in A
      candidate_a = setup_candidate(tenant_a, "mismatch")

      conn = candidate_session(conn, tenant_a, candidate_a)
      conn = get(conn, ~p"/#{tenant_b.slug}/portal")

      # plug should redirect to candidate's real tenant portal
      assert redirected_to(conn) =~ "/#{tenant_a.slug}/portal"
    end
  end

  describe "duplicate application feedback" do
    test "second submit shows duplicate notice", %{conn: conn} do
      tenant = setup_tenant("dup")

      if is_nil(Pipeline.default_pipeline_id(tenant.id)),
        do: Treby.Pipeline.create_default_pipeline_stages(tenant)

      job = setup_job(tenant)

      # first submit
      {:ok, view, _html} = live(conn, ~p"/#{tenant.slug}/careers/#{job.id}/apply")

      html =
        view
        |> form("#apply-form", %{
          "application[name]" => "Dup Test",
          "application[email]" => "dup-#{System.unique_integer([:positive])}@test.com",
          "application[phone]" => "555-0100"
        })
        |> render_submit()

      assert html =~ "Thank you"

      # reuse same email for second submit (need to reload view)
      email = "dup-reuse-#{System.unique_integer([:positive])}@test.com"
      # create first via live then second via new live to reuse same candidate email
      # First application via live with email
      {:ok, view2, _} = live(conn, ~p"/#{tenant.slug}/careers/#{job.id}/apply")

      html2 =
        view2
        |> form("#apply-form", %{
          "application[name]" => "Dup Test",
          "application[email]" => email,
          "application[phone]" => "555-0100"
        })
        |> render_submit()

      assert html2 =~ "Thank you"

      # second attempt same email same job
      {:ok, view3, _} = live(conn, ~p"/#{tenant.slug}/careers/#{job.id}/apply")

      html3 =
        view3
        |> form("#apply-form", %{
          "application[name]" => "Dup Test",
          "application[email]" => email,
          "application[phone]" => "555-0100"
        })
        |> render_submit()

      assert html3 =~ "already applied" or html3 =~ "duplicate-notice"
      assert html3 =~ "duplicate-notice"
    end
  end
end
