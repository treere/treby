defmodule TrebyWeb.CareersLive.SearchTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo}
  alias Treby.Jobs.Job

  defp setup_tenant_with_jobs do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Search Corp #{System.unique_integer([:positive])}",
        slug: "careers-search-#{System.unique_integer([:positive])}"
      })

    for {title, description} <- [{"DevOps Engineer", "infra"}, {"Product Designer", "figma"}] do
      {:ok, _} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{
          title: title,
          description: description,
          status: "open",
          visible: true
        })
        |> Repo.insert()
    end

    tenant
  end

  test "tenant careers search is in the URL and persists on reload", %{conn: conn} do
    tenant = setup_tenant_with_jobs()
    {:ok, view, html} = live(conn, ~p"/#{tenant.slug}/careers")
    assert html =~ "DevOps Engineer"
    assert html =~ "Product Designer"

    view
    |> form("form[phx-submit=search]", %{"query" => "devops"})
    |> render_submit()

    assert_patch(view, "/#{tenant.slug}/careers?query=devops")

    {:ok, _view2, html2} = live(conn, "/#{tenant.slug}/careers?query=devops")
    assert html2 =~ "DevOps Engineer"
    refute html2 =~ "Product Designer"
  end

  test "clearing the tenant search returns to the bare path", %{conn: conn} do
    tenant = setup_tenant_with_jobs()
    {:ok, view, _html} = live(conn, "/#{tenant.slug}/careers?query=devops")

    view
    |> form("form[phx-submit=search]", %{"query" => ""})
    |> render_submit()

    assert_patch(view, "/#{tenant.slug}/careers")
  end

  test "global careers search is in the URL and persists on reload", %{conn: conn} do
    _tenant = setup_tenant_with_jobs()
    {:ok, view, _html} = live(conn, ~p"/careers")

    view
    |> form("form[phx-submit=search]", %{"query" => "devops"})
    |> render_submit()

    assert_patch(view, "/careers?query=devops")

    {:ok, _view2, html2} = live(conn, "/careers?query=devops")
    assert html2 =~ "DevOps Engineer"
    refute html2 =~ "Product Designer"
  end
end
