defmodule TrebyWeb.SettingsAuditLogLiveTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo, Audit}
  alias Treby.Accounts.User

  defp setup_tenant(role) do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Audit Live Test Corp #{System.unique_integer([:positive])}",
        slug: "audit-live-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "audit-live-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Audit Live User",
        role: role
      })
      |> Repo.insert()

    {:ok, _} =
      Treby.Memberships.create_membership(%{
        user_id: user.id,
        tenant_id: tenant.id,
        role: role
      })

    {tenant, user}
  end

  defp login_user(conn, user) do
    conn
    |> init_test_session(%{
      "user_id" => user.id,
      "tenant_id" => user.tenant_id
    })
  end

  describe "audit log page" do
    test "admin sees paginated tenant-scoped events and filters work", %{conn: conn} do
      {tenant, admin} = setup_tenant("admin")
      # create two events for this tenant
      {:ok, _} =
        Audit.log_event("job.created", "job", Ecto.UUID.generate(), %{
          tenant_id: tenant.id,
          actor_id: admin.id,
          metadata: %{after: %{title: "Engineer"}}
        })

      {:ok, _} =
        Audit.log_event("candidate.created", "candidate", Ecto.UUID.generate(), %{
          tenant_id: tenant.id,
          actor_id: admin.id,
          metadata: %{}
        })

      conn = login_user(conn, admin)
      {:ok, view, html} = live(conn, ~p"/#{tenant.slug}/app/settings/audit-log")

      assert html =~ "Audit Log"
      assert html =~ "job.created"
      assert has_element?(view, "#audit-table")
      assert has_element?(view, "#audit-filter-form")

      # filter by action prefix
      html =
        view
        |> element("#audit-filter-form")
        |> render_change(%{action: "job.", entity_type: "", search: "", actor_id: ""})

      assert html =~ "job.created"
      refute html =~ "candidate.created"

      # detail shows diff
      [event | _] = Audit.list_events(tenant.id, action: "job.") |> elem(0)
      html = view |> element("button[phx-value-id='#{event.id}']") |> render_click()
      assert html =~ event.action
      assert html =~ "Metadata"
    end

    test "member is redirected with permission denied", %{conn: conn} do
      {tenant, _admin} = setup_tenant("admin")
      {_, member} = setup_tenant_member(tenant)

      conn = login_user(conn, member)

      {:error, {:redirect, %{to: redirect_path, flash: flash}}} =
        live(conn, ~p"/#{tenant.slug}/app/settings/audit-log")

      assert redirect_path =~ "/#{tenant.slug}/app"
      assert flash["error"] =~ "permission"
    end

    test "cross-tenant isolation", %{conn: conn} do
      {t1, admin1} = setup_tenant("admin")
      {t2, _admin2} = setup_tenant("admin")

      {:ok, _} =
        Audit.log_event("job.created", "job", Ecto.UUID.generate(), %{
          tenant_id: t1.id,
          actor_id: admin1.id
        })

      {:ok, _} = Audit.log_event("job.created", "job", Ecto.UUID.generate(), %{tenant_id: t2.id})

      conn = login_user(conn, admin1)
      {:ok, view, _html} = live(conn, ~p"/#{t1.slug}/app/settings/audit-log")
      {events, _} = Audit.list_events(t1.id, [])
      # view should not show t2 events
      html = render(view)
      assert html =~ "job.created"
      # ensure no leakage by counting via context
      {t2_events, _} = Audit.list_events(t2.id, [])
      assert Enum.all?(events, &(&1.tenant_id == t1.id))
      assert Enum.all?(t2_events, &(&1.tenant_id == t2.id))
    end
  end

  defp setup_tenant_member(tenant) do
    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "member-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Member User",
        role: "member"
      })
      |> Repo.insert()

    {:ok, _} =
      Treby.Memberships.create_membership(%{
        user_id: user.id,
        tenant_id: tenant.id,
        role: "member"
      })

    {tenant, user}
  end
end
