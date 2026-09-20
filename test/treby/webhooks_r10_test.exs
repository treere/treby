defmodule Treby.WebhooksR10Test do
  use Treby.DataCase, async: true

  alias Treby.{Tenants, Webhooks, Repo}
  alias Treby.Accounts.User

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "R10 #{System.unique_integer([:positive])}",
        slug: "r10-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "r10-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "R10",
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

  test "http URL is now accepted (R10 fix)" do
    {tenant, _} = setup_tenant()

    {:ok, sub} =
      Webhooks.create_subscription(tenant.id, %{
        target_url: "http://example.com/hook",
        events_text: "candidate.*",
        description: "http test"
      })
      |> Webhooks.save_subscription()

    assert sub.target_url == "http://example.com/hook"
  end

  test "https URL still accepted" do
    {tenant, _} = setup_tenant()

    {:ok, sub} =
      Webhooks.create_subscription(tenant.id, %{
        target_url: "https://example.com/hook",
        events_text: "candidate.*"
      })
      |> Webhooks.save_subscription()

    assert sub.target_url == "https://example.com/hook"
  end

  test "invalid URL without http/https is rejected" do
    {tenant, _} = setup_tenant()

    {:error, changeset} =
      Webhooks.create_subscription(tenant.id, %{
        target_url: "ftp://example.com/hook",
        events_text: "candidate.*"
      })
      |> Webhooks.save_subscription()

    assert changeset.errors[:target_url] != nil
    assert elem(changeset.errors[:target_url], 0) =~ "http"
  end

  test "test_ping accepts both http and https" do
    # Stub GoogleApiMock to handle webhook ping (since Req in test goes through that mock)
    Req.Test.stub(Treby.GoogleApiMock, fn conn ->
      Plug.Conn.send_resp(conn, 200, "ok")
    end)

    {:error, reason} = Webhooks.test_ping("ftp://example.com/hook", "secret")
    assert reason =~ "http"
    result_http = Webhooks.test_ping("http://example.com/hook", "secret")
    assert {:ok, 200} = result_http
    result_https = Webhooks.test_ping("https://example.com/hook", "secret")
    assert {:ok, 200} = result_https
  end
end
