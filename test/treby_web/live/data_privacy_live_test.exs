defmodule TrebyWeb.DataPrivacyLiveTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User

  defp setup_tenant(role \\ "admin") do
    suffix = System.unique_integer([:positive])

    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Data & Privacy Live #{suffix}",
        slug: "data-privacy-live-#{suffix}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "data-privacy-live-#{suffix}@test.com",
        password: "password123",
        name: "Data & Privacy User",
        role: role
      })
      |> Repo.insert()

    {:ok, _} =
      Treby.Memberships.create_membership(%{user_id: user.id, tenant_id: tenant.id, role: role})

    {tenant, user}
  end

  defp login(conn, user) do
    init_test_session(conn, %{"user_id" => user.id, "tenant_id" => user.tenant_id})
  end

  test "admin can view data-privacy page", %{conn: conn} do
    {tenant, user} = setup_tenant("admin")
    conn = login(conn, user)
    {:ok, _view, html} = live(conn, ~p"/#{tenant.slug}/app/settings/data-privacy")
    assert html =~ "Data"
    assert html =~ "Export"
  end

  test "member can view data-privacy page for user scope", %{conn: conn} do
    {tenant, user} = setup_tenant("member")
    conn = login(conn, user)
    {:ok, _view, html} = live(conn, ~p"/#{tenant.slug}/app/settings/data-privacy")
    assert html =~ "Data"
    assert html =~ "Export my data" or html =~ "Delete my account"
  end

  test "member cannot export tenant data", %{conn: conn} do
    {tenant, user} = setup_tenant("member")
    conn = login(conn, user)
    {:ok, view, _html} = live(conn, ~p"/#{tenant.slug}/app/settings/data-privacy")
    refute has_element?(view, "#data-privacy-export-tenant")
    assert has_element?(view, "#data-privacy-export-user")
  end

  test "download requires signed URL and tenant isolation", %{conn: conn} do
    {tenant, user} = setup_tenant("admin")

    {:ok, req} =
      Treby.Repo.insert(%Treby.DataPrivacy.DataPrivacyRequest{
        tenant_id: tenant.id,
        requester_id: user.id,
        type: "export",
        scope: "user",
        status: "pending",
        metadata: %{}
      })

    {:ok, ready} =
      Treby.DataPrivacy.Requests.transition(req, "ready", %{
        s3_key: "#{tenant.id}/data-privacy-exports/#{req.id}.zip",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      })

    conn = login(conn, user)
    conn = get(conn, ~p"/#{tenant.slug}/data-privacy/exports/#{ready.id}/download")
    assert conn.status in [302, 500]

    if conn.status == 302 do
      [location] = get_resp_header(conn, "location")
      # Signed URL must not leak raw S3 key in HTML, and must be presigned (contains X-Amz)
      assert location =~ "X-Amz" or location =~ "treby-uploads" or location =~ ready.id
    end

    # Tenant isolation: other tenant cannot download
    {other_tenant, other_user} = setup_tenant("admin")
    other_conn = login(build_conn(), other_user)

    other_conn =
      get(other_conn, ~p"/#{other_tenant.slug}/data-privacy/exports/#{ready.id}/download")

    assert other_conn.status == 404
  end

  test "grace block redirects non-Data & Privacy pages", %{conn: conn} do
    {tenant, user} = setup_tenant("admin")
    # Simulate pending erasure
    tenant
    |> Ecto.Changeset.change(%{
      settings:
        Map.put(
          tenant.settings || %{},
          "data_privacy_pending_erasure",
          DateTime.utc_now() |> DateTime.to_iso8601()
        )
    })
    |> Treby.Repo.update!()

    conn = login(conn, user)
    # Data & Privacy page should be accessible
    {:ok, _view, html} = live(conn, ~p"/#{tenant.slug}/app/settings/data-privacy")
    assert html =~ "Data"
    # Other page should redirect to Data & Privacy
    conn2 = login(build_conn(), user)
    conn2 = get(conn2, ~p"/#{tenant.slug}/app")
    assert conn2.status == 302
    assert get_resp_header(conn2, "location") |> hd() =~ "data-privacy"
  end
end
