defmodule TrebyWeb.CareersLive.ApplyUploadTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Jobs, Pipeline, Repo}
  alias Treby.Jobs.Job
  alias Treby.Pipeline.PipelineStage

  defp setup_tenant_with_job(support_email \\ nil) do
    slug = "apply-test-#{System.unique_integer([:positive])}"
    {:ok, tenant} = Tenants.create_tenant(%{name: "Apply Test Corp", slug: slug})

    tenant =
      if support_email do
        {:ok, t} = Tenants.update_tenant(tenant, %{settings: %{"support_email" => support_email}})
        t
      else
        tenant
      end

    pipeline_id = Pipeline.default_pipeline_id(tenant.id)
    pipeline = Repo.get!(Treby.Pipeline.Pipeline, pipeline_id)

    {:ok, _stage} =
      pipeline
      |> Ecto.build_assoc(:pipeline_stages)
      |> PipelineStage.changeset(%{name: "Applied", position: 0})
      |> Repo.insert()

    {:ok, job} =
      tenant
      |> Ecto.build_assoc(:jobs)
      |> Job.changeset(%{title: "Test Job", status: "open", description: "Desc", visible: true})
      |> Repo.insert()

    {tenant, job}
  end

  describe "resume upload feedback" do
    test "apply page renders resume upload with id and entries area", %{conn: conn} do
      {tenant, job} = setup_tenant_with_job()
      {:ok, view, _html} = live(conn, ~p"/#{tenant.slug}/careers/#{job.id}/apply")
      html = render(view)
      assert html =~ "Resume (PDF, DOC, DOCX"
      assert html =~ "resume-upload"
      assert html =~ "Submit Application"
    end

    test "valid PDF shows filename and size after selection", %{conn: conn} do
      {tenant, job} = setup_tenant_with_job()
      {:ok, view, _html} = live(conn, ~p"/#{tenant.slug}/careers/#{job.id}/apply")

      view
      |> file_input("#apply-form", :resume, [
        %{name: "resume.pdf", content: String.duplicate("a", 1000), type: "application/pdf"}
      ])
      |> render_upload("resume.pdf")

      html = render(view)
      assert html =~ "resume.pdf"
      assert html =~ "Remove"
    end

    test "JPG shows not_accepted error", %{conn: conn} do
      {tenant, job} = setup_tenant_with_job()
      {:ok, view, _html} = live(conn, ~p"/#{tenant.slug}/careers/#{job.id}/apply")

      view
      |> file_input("#apply-form", :resume, [
        %{name: "photo.jpg", content: "fake", type: "image/jpeg"}
      ])
      |> render_upload("photo.jpg")

      html = render(view)
      assert html =~ "File type not accepted"
    end

    test "submit with no file still succeeds", %{conn: conn} do
      {tenant, job} = setup_tenant_with_job()
      {:ok, view, html} = live(conn, ~p"/#{tenant.slug}/careers/#{job.id}/apply")
      assert html =~ "Apply for Test Job"

      email = "nofile-#{System.unique_integer([:positive])}@test.com"

      html =
        view
        |> form("#apply-form", %{
          "application" => %{"name" => "No File User", "email" => email, "phone" => "123"}
        })
        |> render_submit()

      assert html =~ "Thank you!"
      assert html =~ "Track your application"
      refute html =~ "support@"
    end

    test "submit with failed upload does not create application silently", %{conn: conn} do
      {tenant, job} = setup_tenant_with_job()
      {:ok, view, _html} = live(conn, ~p"/#{tenant.slug}/careers/#{job.id}/apply")

      view
      |> file_input("#apply-form", :resume, [
        %{name: "bad.jpg", content: "x", type: "image/jpeg"}
      ])
      |> render_upload("bad.jpg")

      html_before = render(view)
      assert html_before =~ "File type not accepted"

      email = "failed-#{System.unique_integer([:positive])}@test.com"

      html =
        view
        |> form("#apply-form", %{"application" => %{"name" => "Fail User", "email" => email}})
        |> render_submit()

      # Flash is via put_flash, but upload error remains visible and no Thank you
      assert html =~ "File type not accepted"
      refute html =~ "Thank you!"
      # Ensure no application created for that email
      assert Treby.Repo.get_by(Treby.Candidates.Candidate, email: email) == nil
    end

    test "help block shows configurable email when present", %{conn: conn} do
      {tenant, job} = setup_tenant_with_job("help@example.com")
      {:ok, view, _html} = live(conn, ~p"/#{tenant.slug}/careers/#{job.id}/apply")
      html = render(view)
      assert html =~ "help@example.com"
      assert html =~ "candidate-help"
    end

    test "help block hidden when no email configured shows no hard-coded support@treby.app", %{
      conn: conn
    } do
      {tenant, job} = setup_tenant_with_job(nil)
      {:ok, view, _html} = live(conn, ~p"/#{tenant.slug}/careers/#{job.id}/apply")
      html = render(view)
      refute html =~ "support@treby.app"
    end
  end
end
