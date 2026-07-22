defmodule TrebyWeb.CareerPageTest do
  use TrebyWeb.ConnCase, async: false

  alias Treby.{Tenants, Repo}
  alias Treby.Careers.CareerPage

  defp setup_tenant_with_career_page do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Career Test Corp",
        slug: "career-test-#{System.unique_integer([:positive])}"
      })

    {:ok, career_page} =
      tenant
      |> Ecto.build_assoc(:career_pages)
      |> CareerPage.changeset(%{
        title: "Join Our Team",
        description: "We are hiring!",
        primary_color: "#3b82f6",
        published: true
      })
      |> Repo.insert()

    {:ok, job} =
      tenant
      |> Ecto.build_assoc(:jobs)
      |> Treby.Jobs.Job.changeset(%{
        title: "Software Engineer",
        description: "Build amazing things",
        salary_range: "$100k-$150k"
      })
      |> Repo.insert()

    {tenant, career_page, job}
  end

  describe "career page" do
    test "public career page lists open jobs", %{conn: conn} do
      {tenant, _career_page, job} = setup_tenant_with_career_page()

      conn = get(conn, ~p"/#{tenant.slug}/careers")

      assert html_response(conn, 200) =~ "Join Our Team"
      assert html_response(conn, 200) =~ job.title
    end

    test "public career page shows job detail", %{conn: conn} do
      {tenant, _career_page, job} = setup_tenant_with_career_page()

      conn = get(conn, ~p"/#{tenant.slug}/careers/#{job.id}")

      assert html_response(conn, 200) =~ job.title
      assert html_response(conn, 200) =~ "Build amazing things"
    end

    test "career page application form renders", %{conn: conn} do
      {tenant, _career_page, job} = setup_tenant_with_career_page()

      conn = get(conn, ~p"/#{tenant.slug}/careers/#{job.id}/apply")

      assert html_response(conn, 200) =~ "Apply for #{job.title}"
      assert html_response(conn, 200) =~ "Full Name"
    end

    test "career page shows closed jobs as not listed", %{conn: conn} do
      {tenant, _career_page, _job} = setup_tenant_with_career_page()

      closed_job =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Treby.Jobs.Job.changeset(%{
          title: "Closed Position",
          description: "No longer open",
          status: "closed"
        })
        |> Repo.insert!()

      conn = get(conn, ~p"/#{tenant.slug}/careers")

      refute html_response(conn, 200) =~ closed_job.title
    end
  end
end
