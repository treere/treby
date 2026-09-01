defmodule TrebyWeb.HealthControllerTest do
  use TrebyWeb.ConnCase, async: false

  describe "GET /health" do
    test "returns 200 with json and no-store headers without authentication", %{conn: conn} do
      conn = get(conn, ~p"/health")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") |> List.first() =~ "application/json"
      assert get_resp_header(conn, "cache-control") |> List.first() =~ "no-store"
      assert get_resp_header(conn, "pragma") |> List.first() == "no-cache"

      body = json_response(conn, 200)
      assert body["status"] == "ok"
    end

    test "does not redirect to login when unauthenticated", %{conn: conn} do
      conn = get(conn, ~p"/health")
      refute conn.status in [301, 302, 401, 403]
      assert conn.status == 200
    end

    test "liveness does not depend on database — still 200 when db check is forced to error",
         %{conn: conn} do
      Application.put_env(:treby, :health_db_status, :error)

      on_exit(fn -> Application.delete_env(:treby, :health_db_status) end)

      conn = get(conn, ~p"/health")
      assert conn.status == 200
      assert json_response(conn, 200)["status"] == "ok"
    end
  end

  describe "GET /healthz alias" do
    test "behaves identically to /health", %{conn: conn} do
      conn = get(conn, ~p"/healthz")
      assert conn.status == 200
      assert get_resp_header(conn, "cache-control") |> List.first() =~ "no-store"
      assert json_response(conn, 200)["status"] == "ok"
    end
  end

  describe "HEAD /health" do
    test "returns 200 with same headers and empty body via Plug.Head", %{conn: conn} do
      conn = head(conn, ~p"/health")
      assert conn.status == 200
      assert get_resp_header(conn, "cache-control") |> List.first() =~ "no-store"
      assert conn.resp_body == ""
    end
  end

  describe "GET /health/ready" do
    test "returns 200 with database ok and storage skipped when db is reachable", %{conn: conn} do
      conn = get(conn, ~p"/health/ready")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") |> List.first() =~ "application/json"
      assert get_resp_header(conn, "cache-control") |> List.first() =~ "no-store"
      assert get_resp_header(conn, "pragma") |> List.first() == "no-cache"

      body = json_response(conn, 200)
      assert body["status"] == "ok"
      assert body["checks"]["database"] == "ok"
      assert body["checks"]["storage"] == "skipped"
    end

    test "returns 503 when database is unreachable (simulated via env override)", %{conn: conn} do
      Application.put_env(:treby, :health_db_status, :error)
      on_exit(fn -> Application.delete_env(:treby, :health_db_status) end)

      conn = get(conn, ~p"/health/ready")
      assert conn.status == 503
      body = json_response(conn, 503)
      assert body["status"] == "error"
      assert body["checks"]["database"] == "error"
      # storage remains skipped and does not mask db error
      assert body["checks"]["storage"] == "skipped"
      # no raw exception leaked
      refute Map.has_key?(body, "error")
      refute inspect(body) =~ "Postgrex"
    end

    test "storage is skipped by default and does not cause 503", %{conn: conn} do
      conn = get(conn, ~p"/health/ready")
      body = json_response(conn, 200)
      assert body["checks"]["storage"] == "skipped"
      assert body["status"] == "ok"
    end

    test "does not require tenant context", %{conn: conn} do
      conn = get(conn, ~p"/health/ready")
      assert conn.status == 200
      # no redirect to login or choose-tenant
      refute conn.status in [302, 401, 403]
    end

    test "does not expose sensitive data", %{conn: conn} do
      conn = get(conn, ~p"/health/ready")
      body = json_response(conn, 200)
      # only expected keys
      assert Map.keys(body) |> Enum.sort() == ["checks", "status"]
      assert Map.keys(body["checks"]) |> Enum.sort() == ["database", "storage"]
    end
  end

  describe "unauthenticated and tenant-agnostic" do
    test "probes succeed without tenant_slug or session", %{conn: _conn} do
      # build_conn is unauthenticated and has no tenant
      for path <- [~p"/health", ~p"/healthz", ~p"/health/ready"] do
        conn = get(build_conn(), path)

        assert conn.status in [200, 503],
               "expected 200 or 503 for #{path}, got #{conn.status}"
      end
    end
  end
end
