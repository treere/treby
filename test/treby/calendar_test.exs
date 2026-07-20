defmodule Treby.CalendarTest do
  use Treby.DataCase, async: true

  alias Treby.Calendar
  alias Treby.Calendar.CalendarConnection

  setup do
    {:ok, tenant} = insert_tenant()
    {:ok, user} = insert_user(tenant.id)
    {:ok, tenant: tenant, user: user}
  end

  describe "connect_google_user/3" do
    test "creates a new connection", %{user: user, tenant: tenant} do
      token_data = %{
        access_token: "access-123",
        refresh_token: "refresh-456",
        expires_at: DateTime.utc_now() |> DateTime.add(1, :hour),
        email: "user@gmail.com"
      }

      assert {:ok, %CalendarConnection{} = conn} =
               Calendar.connect_google_user(user.id, tenant.id, token_data)

      assert conn.provider == "google"
      assert conn.google_email == "user@gmail.com"
      assert conn.calendar_id == "primary"
      assert conn.user_id == user.id
      assert conn.tenant_id == tenant.id
    end

    test "updates existing connection on reconnect", %{user: user, tenant: tenant} do
      token_data = %{
        access_token: "access-old",
        refresh_token: "refresh-old",
        expires_at: DateTime.utc_now() |> DateTime.add(1, :hour),
        email: "user@gmail.com"
      }

      {:ok, _} = Calendar.connect_google_user(user.id, tenant.id, token_data)

      updated_data = %{
        access_token: "access-new",
        refresh_token: "refresh-new",
        expires_at: DateTime.utc_now() |> DateTime.add(2, :hour),
        email: "user@gmail.com"
      }

      assert {:ok, %CalendarConnection{} = conn} =
               Calendar.connect_google_user(user.id, tenant.id, updated_data)

      assert conn.access_token == "access-new"
    end
  end

  describe "get_connection/1" do
    test "returns connection when exists", %{user: user, tenant: tenant} do
      token_data = valid_token_data()

      {:ok, _} = Calendar.connect_google_user(user.id, tenant.id, token_data)

      assert %CalendarConnection{} = Calendar.get_connection(user.id)
    end

    test "returns nil when no connection", %{user: user} do
      assert Calendar.get_connection(user.id) == nil
    end
  end

  describe "connected?/1" do
    test "returns true when connected", %{user: user, tenant: tenant} do
      {:ok, _} = Calendar.connect_google_user(user.id, tenant.id, valid_token_data())
      assert Calendar.connected?(user.id) == true
    end

    test "returns false when not connected", %{user: user} do
      assert Calendar.connected?(user.id) == false
    end
  end

  describe "disconnect_google_user/1" do
    test "deletes the connection", %{user: user, tenant: tenant} do
      {:ok, _} = Calendar.connect_google_user(user.id, tenant.id, valid_token_data())
      assert Calendar.connected?(user.id)

      Calendar.disconnect_google_user(user.id)
      refute Calendar.connected?(user.id)
    end
  end

  describe "list_connected_users/1" do
    test "returns connections for the tenant", %{user: user, tenant: tenant} do
      {:ok, _} = Calendar.connect_google_user(user.id, tenant.id, valid_token_data())

      connections = Calendar.list_connected_users(tenant.id)
      assert length(connections) == 1
    end

    test "returns empty list when no connections", %{tenant: tenant} do
      assert Calendar.list_connected_users(tenant.id) == []
    end
  end

  describe "get_free_busy/3" do
    test "returns error when not connected", %{user: user} do
      assert Calendar.get_free_busy(
               user.id,
               DateTime.utc_now(),
               DateTime.add(DateTime.utc_now(), 1, :hour)
             ) ==
               {:error, :not_connected}
    end
  end

  describe "create_event_with_meet/3" do
    test "returns error when not connected", %{user: user} do
      params = %{
        summary: "Test",
        start_at: DateTime.utc_now(),
        end_at: DateTime.add(DateTime.utc_now(), 1800, :second),
        timezone: "UTC"
      }

      assert Calendar.create_event_with_meet(user.id, params) == {:error, :not_connected}
    end
  end

  describe "delete_event/2" do
    test "returns error when not connected", %{user: user} do
      assert Calendar.delete_event(user.id, "some-event-id") == {:error, :not_connected}
    end
  end

  describe "Google.get_valid_token/1" do
    test "returns access_token when token is still valid", %{user: user, tenant: tenant} do
      token_data = %{
        access_token: "valid-token",
        refresh_token: "refresh-token",
        expires_at: DateTime.utc_now() |> DateTime.add(1, :hour),
        email: "user@gmail.com"
      }

      {:ok, _} = Calendar.connect_google_user(user.id, tenant.id, token_data)
      conn = Calendar.get_connection(user.id)

      assert {:ok, "valid-token"} = Calendar.Google.get_valid_token(conn)
    end

    test "returns error when no refresh token and token expired" do
      conn = %CalendarConnection{
        access_token: "expired-token",
        refresh_token: nil,
        token_expires_at: DateTime.add(DateTime.utc_now(), -1, :hour)
      }

      assert {:error, :no_refresh_token} = Calendar.Google.get_valid_token(conn)
    end

    test "returns error when token_expires_at is nil" do
      conn = %CalendarConnection{
        access_token: "some-token",
        refresh_token: "refresh",
        token_expires_at: nil
      }

      assert_raise RuntimeError, fn ->
        Calendar.Google.get_valid_token(conn)
      end
    end

    test "returns error when access_token is nil" do
      conn = %CalendarConnection{
        access_token: nil,
        refresh_token: "refresh",
        token_expires_at: DateTime.utc_now() |> DateTime.add(1, :hour)
      }

      assert_raise RuntimeError, fn ->
        Calendar.Google.get_valid_token(conn)
      end
    end
  end

  defp valid_token_data do
    %{
      access_token: "access-#{System.unique_integer([:positive])}",
      refresh_token: "refresh-#{System.unique_integer([:positive])}",
      expires_at: DateTime.utc_now() |> DateTime.add(1, :hour),
      email: "user-#{System.unique_integer([:positive])}@gmail.com"
    }
  end

  defp insert_tenant do
    Treby.Repo.insert!(%Treby.Tenants.Tenant{
      name: "Test Tenant",
      slug: "test-#{System.unique_integer([:positive])}"
    })
    |> then(&{:ok, &1})
  end

  defp insert_user(tenant_id) do
    Treby.Repo.insert!(%Treby.Accounts.User{
      name: "Test User",
      email: "test-#{System.unique_integer([:positive])}@example.com",
      password_hash: Bcrypt.hash_pwd_salt("password123456"),
      tenant_id: tenant_id
    })
    |> then(&{:ok, &1})
  end
end
