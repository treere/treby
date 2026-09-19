defmodule TrebyWeb.ScorecardTemplateR14Test do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User

  defp setup_tenant do
    suffix = System.unique_integer([:positive])
    {:ok, tenant} = Tenants.create_tenant(%{name: "R14 #{suffix}", slug: "r14-#{suffix}"})

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "r14-#{suffix}@test.com",
        password: "password123",
        name: "R14",
        role: "admin"
      })
      |> Repo.insert()

    {:ok, _} =
      Treby.Memberships.create_membership(%{
        user_id: user.id,
        tenant_id: tenant.id,
        role: "admin"
      })

    {tenant, user}
  end

  test "add scorecard template with empty name shows can't be blank", %{conn: conn} do
    {tenant, user} = setup_tenant()
    conn = init_test_session(conn, %{"user_id" => user.id})
    {:ok, view, _html} = live(conn, "/#{tenant.slug}/app/settings/scorecards")

    view |> element("button", "Add Template") |> render_click()

    html = view |> form("#template-form", %{"name" => ""}) |> render_submit()

    assert html =~ "can&#39;t be blank" or html =~ "can&apos;t be blank"
  end
end
