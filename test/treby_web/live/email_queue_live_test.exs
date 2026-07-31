defmodule TrebyWeb.EmailQueueLive.IndexTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, EmailQueue, Repo}
  alias Treby.Accounts.User

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Queue Test Corp",
        slug: "queue-test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "queue-test-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Queue User",
        role: "admin"
      })
      |> Repo.insert()

    {tenant, user}
  end

  defp login_user(conn, user) do
    conn
    |> init_test_session(%{
      "user_id" => user.id,
      "tenant_id" => user.tenant_id
    })
  end

  defp create_scheduled_email(tenant, overrides \\ %{}) do
    later = DateTime.add(DateTime.utc_now(), 3600, :second)

    {:ok, email} =
      EmailQueue.create_scheduled_email(
        Map.merge(
          %{
            tenant_id: tenant.id,
            scheduled_at: later,
            to_address: "candidate@example.com",
            from_address: "recruiter@example.com",
            subject: "Test Subject",
            html_body: "<p>Test</p>",
            email_type: "compose"
          },
          Map.new(overrides)
        )
      )

    email
  end

  describe "email queue page" do
    test "renders empty state when no emails" do
      {_tenant, user} = setup_tenant()
      conn = login_user(build_conn(), user)

      {:ok, _view, html} = live(conn, ~p"/app/email-queue")

      assert html =~ "Email Queue"
      assert html =~ "No queued emails"
    end

    test "shows queued emails" do
      {tenant, user} = setup_tenant()
      scheduled = create_scheduled_email(tenant)
      conn = login_user(build_conn(), user)

      {:ok, _view, html} = live(conn, ~p"/app/email-queue")

      assert html =~ scheduled.subject
    end

    test "toggles between tabs" do
      {tenant, user} = setup_tenant()
      create_scheduled_email(tenant)
      conn = login_user(build_conn(), user)

      {:ok, view, _html} = live(conn, ~p"/app/email-queue")

      view |> element(~s{[phx-value-tab="sent"]}) |> render_click()

      assert render(view) =~ "No sent emails yet"
    end
  end

  describe "actions" do
    test "cancel action marks email as cancelled" do
      {tenant, user} = setup_tenant()
      create_scheduled_email(tenant)
      conn = login_user(build_conn(), user)

      {:ok, view, _html} = live(conn, ~p"/app/email-queue")

      view |> element(~s{button[phx-click="cancel"]}) |> render_click()

      assert render(view) =~ "Email cancelled"
    end

    test "open edit modal" do
      {tenant, user} = setup_tenant()
      create_scheduled_email(tenant)
      conn = login_user(build_conn(), user)

      {:ok, view, _html} = live(conn, ~p"/app/email-queue")

      view |> element(~s{button[phx-click="open_edit"]}) |> render_click()

      assert render(view) =~ "Edit Scheduled Email"
    end

    test "bulk cancel cancels selected emails" do
      {tenant, user} = setup_tenant()
      create_scheduled_email(tenant, subject: "Bulk one")
      create_scheduled_email(tenant, subject: "Bulk two")
      conn = login_user(build_conn(), user)

      {:ok, view, _html} = live(conn, ~p"/app/email-queue")

      view |> element(~s{input[phx-click="select_all"]}) |> render_click()
      view |> element(~s{button[phx-click="bulk_cancel"]}) |> render_click()

      assert render(view) =~ "2 emails cancelled"
    end
  end
end
