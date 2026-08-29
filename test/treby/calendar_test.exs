defmodule Treby.CalendarTest do
  use Treby.DataCase, async: true

  alias Treby.Calendar
  alias Treby.Calendar.CalendarConnection
  alias Treby.Calendar.Providers.Jitsi
  alias Treby.GoogleApiMock

  import Req.Test
  alias Plug.Conn

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
      assert conn.provider_email == "user@gmail.com"
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

      assert %CalendarConnection{} = Calendar.get_connection(user.id, "google")
    end

    test "returns nil when no connection", %{user: user} do
      assert Calendar.get_connection(user.id, "google") == nil
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
               "google",
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

      assert Calendar.create_event_with_meet(user.id, "google", params) ==
               {:error, :not_connected}
    end
  end

  describe "delete_event/3" do
    test "returns error when not connected", %{user: user} do
      assert Calendar.delete_event(user.id, "google", "some-event-id") ==
               {:error, :not_connected}
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
      conn = Calendar.get_connection(user.id, "google")

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

    test "refreshes token when token_expires_at is nil", %{user: user, tenant: tenant} do
      token_data = %{
        access_token: "expired-token",
        refresh_token: "refresh",
        expires_at: nil,
        email: "user@gmail.com"
      }

      {:ok, _} = Calendar.connect_google_user(user.id, tenant.id, token_data)
      conn = Calendar.get_connection(user.id, "google")
      GoogleApiMock.stub_token_refresh("refreshed-token")

      assert {:ok, "refreshed-token"} = Calendar.Google.get_valid_token(conn)

      updated = Calendar.get_connection(user.id, "google")
      assert updated.access_token == "refreshed-token"
      assert DateTime.compare(updated.token_expires_at, DateTime.utc_now()) == :gt
    end

    test "refreshes token when access_token is nil", %{user: user, tenant: tenant} do
      token_data = %{
        access_token: nil,
        refresh_token: "refresh",
        expires_at: DateTime.utc_now() |> DateTime.add(1, :hour),
        email: "user@gmail.com"
      }

      {:ok, _} = Calendar.connect_google_user(user.id, tenant.id, token_data)
      conn = Calendar.get_connection(user.id, "google")
      GoogleApiMock.stub_token_refresh("refreshed-token")

      assert {:ok, "refreshed-token"} = Calendar.Google.get_valid_token(conn)
    end

    test "returns refresh_failed when token refresh is rejected", %{user: user, tenant: tenant} do
      token_data = %{
        access_token: "expired-token",
        refresh_token: "refresh",
        expires_at: DateTime.utc_now() |> DateTime.add(-1, :hour),
        email: "user@gmail.com"
      }

      {:ok, _} = Calendar.connect_google_user(user.id, tenant.id, token_data)
      conn = Calendar.get_connection(user.id, "google")
      GoogleApiMock.stub_token_error(400, %{"error" => "invalid_grant"})

      assert {:error, {:refresh_failed, resp}} = Calendar.Google.get_valid_token(conn)
      assert resp["error"] == "invalid_grant"
    end
  end

  describe "resolve_meeting/1" do
    test "returns calendar_event with owner when an examiner is Google-connected", %{
      user: user,
      tenant: tenant
    } do
      {:ok, other} = insert_user(tenant.id)
      {:ok, _} = Calendar.connect_google_user(user.id, tenant.id, valid_token_data())

      assert Calendar.resolve_meeting([other.id, user.id]) ==
               {:calendar_event, user.id, :google_meet}
    end

    test "returns jitsi when no examiner is Google-connected", %{
      user: user,
      tenant: tenant
    } do
      {:ok, other} = insert_user(tenant.id)

      assert Calendar.resolve_meeting([user.id, other.id]) == {:meeting_url, :jitsi}
    end
  end

  describe "Providers.Jitsi" do
    test "generates a meet.jit.si link with tenant slug and uuid", %{} do
      assert {:ok, url} = Jitsi.create_meeting_link(%{tenant_slug: "acme"})

      assert url =~ ~r|^https://meet\.jit\.si/treby-acme-[0-9a-f-]{36}$|
    end
  end

  describe "create_event_with_meet/4" do
    test "creates a single event with all examiners and the candidate as attendees", %{
      user: user,
      tenant: tenant
    } do
      {:ok, _} = Calendar.connect_google_user(user.id, tenant.id, valid_token_data())

      GoogleApiMock.stub_event_create("evt-123", "https://meet.google.com/xyz")

      params = %{
        summary: "Interview",
        description: "",
        start_at: DateTime.utc_now(),
        end_at: DateTime.add(DateTime.utc_now(), 1800, :second),
        timezone: "UTC"
      }

      assert {:ok, result} =
               Calendar.create_event_with_meet(
                 user.id,
                 "google",
                 params,
                 ["examiner@example.com", "candidate@example.com"]
               )

      assert result.provider_event_id == "evt-123"
      assert result.video_link == "https://meet.google.com/xyz"
    end

    test "sendUpdates is none so no attendee emails are sent", %{
      user: user,
      tenant: tenant
    } do
      {:ok, _} = Calendar.connect_google_user(user.id, tenant.id, valid_token_data())

      Req.Test.stub(Treby.GoogleApiMock, fn conn ->
        assert conn.request_path == "/calendar/v3/calendars/primary/events"
        assert conn.query_params["sendUpdates"] == "none"

        attendees = conn.body_params["attendees"]
        send(self(), {:attendees, attendees})

        conn
        |> Conn.put_status(200)
        |> json(%{"id" => "evt-1", "hangoutLink" => "https://meet.google.com/abc"})
      end)

      params = %{
        summary: "Interview",
        description: "",
        start_at: DateTime.utc_now(),
        end_at: DateTime.add(DateTime.utc_now(), 1800, :second),
        timezone: "UTC"
      }

      {:ok, _result} =
        Calendar.create_event_with_meet(
          user.id,
          "google",
          params,
          ["examiner@example.com", "candidate@example.com"]
        )

      assert_receive {:attendees, attendees}

      assert Enum.map(attendees, & &1["email"]) ==
               ["examiner@example.com", "candidate@example.com"]
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
