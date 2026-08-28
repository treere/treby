defmodule TrebyWeb.CandidateOtpFlowTest do
  use TrebyWeb.ConnCase, async: false

  import Swoosh.TestAssertions

  alias Treby.{Tenants, Repo}
  alias Treby.Candidates.Candidate

  defp setup_tenant_and_candidate do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "OTP Test Corp",
        slug: "otp-test-#{System.unique_integer([:positive])}"
      })

    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidate.changeset(%{
        name: "OTP Candidate",
        email: "otp-candidate-#{System.unique_integer([:positive])}@test.com"
      })
      |> Repo.insert()

    {tenant, candidate}
  end

  defp extract_code(email) do
    [code | _] = Regex.run(~r/(\d{6})/, email.text_body)
    code
  end

  defp capture_email do
    assert_received {:email, email}
    email
  end

  describe "OTP login flow" do
    test "requests a code and redirects to verify page", %{conn: conn} do
      {tenant, candidate} = setup_tenant_and_candidate()

      conn =
        post(conn, ~p"/#{tenant.slug}/portal/login", %{
          "email" => candidate.email
        })

      assert redirected_to(conn) == "/#{tenant.slug}/portal/verify"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) ==
               "Check your email for your login code"

      email = capture_email()
      assert email.subject == "Your login code"
      assert String.length(extract_code(email)) == 6
    end

    test "unknown email shows same success message (no enumeration)", %{conn: conn} do
      {tenant, _candidate} = setup_tenant_and_candidate()

      conn =
        post(conn, ~p"/#{tenant.slug}/portal/login", %{
          "email" => "unknown-email@test.com"
        })

      assert redirected_to(conn) == "/#{tenant.slug}/portal/verify"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) ==
               "Check your email for your login code"

      assert_no_email_sent()
    end

    test "verifies a valid code and creates a session", %{conn: conn} do
      {tenant, candidate} = setup_tenant_and_candidate()

      conn =
        post(conn, ~p"/#{tenant.slug}/portal/login", %{
          "email" => candidate.email
        })

      email = capture_email()
      code = extract_code(email)

      conn =
        post(conn, ~p"/#{tenant.slug}/portal/verify", %{
          "code" => code
        })

      assert redirected_to(conn) == "/#{tenant.slug}/portal"
      assert get_session(conn, "candidate_id") == candidate.id
      assert get_session(conn, "candidate_expires_at") != nil
    end

    test "rejects an invalid code", %{conn: conn} do
      {tenant, candidate} = setup_tenant_and_candidate()

      conn =
        post(conn, ~p"/#{tenant.slug}/portal/login", %{
          "email" => candidate.email
        })

      capture_email()

      conn =
        post(conn, ~p"/#{tenant.slug}/portal/verify", %{
          "code" => "000000"
        })

      assert redirected_to(conn) == "/#{tenant.slug}/portal/verify"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "Invalid or expired code. Please try again."
    end

    test "cannot reuse a code after success", %{conn: conn} do
      {tenant, candidate} = setup_tenant_and_candidate()

      conn =
        post(conn, ~p"/#{tenant.slug}/portal/login", %{
          "email" => candidate.email
        })

      email = capture_email()
      code = extract_code(email)

      conn =
        post(conn, ~p"/#{tenant.slug}/portal/verify", %{
          "code" => code
        })

      assert redirected_to(conn) == "/#{tenant.slug}/portal"

      # Fresh connection, attempt to reuse the already used code
      fresh =
        build_conn()
        |> init_test_session(%{"otp_email" => candidate.email})

      conn =
        post(fresh, ~p"/#{tenant.slug}/portal/verify", %{
          "code" => code
        })

      assert redirected_to(conn) == "/#{tenant.slug}/portal/verify"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "Invalid or expired code. Please try again."
    end

    test "logout clears the candidate session", %{conn: conn} do
      {tenant, candidate} = setup_tenant_and_candidate()

      conn =
        post(conn, ~p"/#{tenant.slug}/portal/login", %{
          "email" => candidate.email
        })

      email = capture_email()
      code = extract_code(email)

      conn =
        post(conn, ~p"/#{tenant.slug}/portal/verify", %{
          "code" => code
        })

      assert get_session(conn, "candidate_id") == candidate.id

      conn = delete(conn, ~p"/#{tenant.slug}/portal/logout")
      assert redirected_to(conn) == "/#{tenant.slug}/portal/login"
      assert get_session(conn, "candidate_id") == nil
    end

    test "expired session redirects to login", %{conn: conn} do
      {tenant, candidate} = setup_tenant_and_candidate()

      expired = DateTime.utc_now() |> DateTime.add(-1, :hour) |> DateTime.to_unix()

      conn =
        conn
        |> init_test_session(%{
          "candidate_id" => candidate.id,
          "candidate_tenant_id" => tenant.id,
          "candidate_expires_at" => expired
        })

      conn = get(conn, ~p"/#{tenant.slug}/portal")
      assert redirected_to(conn) == "/#{tenant.slug}/portal/login"
      assert get_session(conn, "candidate_id") == nil
    end
  end
end
