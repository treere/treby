defmodule TrebyWeb.CandidatePortalLive.OtpUxTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions

  alias Treby.{Tenants, Repo}
  alias Treby.Candidates.Candidate

  defp setup_tenant_and_candidate do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "OTP UX Corp",
        slug: "otp-ux-#{System.unique_integer([:positive])}"
      })

    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidate.changeset(%{
        name: "OTP UX Candidate",
        email: "otp-ux-#{System.unique_integer([:positive])}@test.com"
      })
      |> Repo.insert()

    {tenant, candidate}
  end

  describe "OTP login UX" do
    test "login page shows expiry and spam helper", %{conn: conn} do
      {tenant, _candidate} = setup_tenant_and_candidate()
      {:ok, view, _html} = live(conn, ~p"/#{tenant.slug}/portal/login")
      html = render(view)
      assert html =~ "Code valid 10 minutes"
      assert html =~ "check spam folder"
      assert html =~ "noreply@treby.app"
      assert html =~ "You can request a new code after 60 seconds"
    end

    test "verify page shows helper and typo recovery link", %{conn: conn} do
      {tenant, candidate} = setup_tenant_and_candidate()

      # Request code to set otp_email session
      conn =
        post(conn, ~p"/#{tenant.slug}/portal/login", %{"email" => candidate.email})

      assert redirected_to(conn) == "/#{tenant.slug}/portal/verify"
      assert_received {:email, _email}

      # Need to follow with session
      conn = get(conn, ~p"/#{tenant.slug}/portal/verify")
      {:ok, view, _html} = live(conn, ~p"/#{tenant.slug}/portal/verify")
      html = render(view)
      assert html =~ "Code valid 10 minutes"
      assert html =~ "check spam folder"
      assert html =~ "Didn"
      assert html =~ "Correct email"
      assert html =~ "You can request a new code after 60 seconds"
      assert html =~ "Resend code"
    end

    test "verify page without email shows helper too", %{conn: conn} do
      {tenant, _candidate} = setup_tenant_and_candidate()
      {:ok, view, _html} = live(conn, ~p"/#{tenant.slug}/portal/verify")
      html = render(view)
      assert html =~ "Code valid 10 minutes"
    end

    test "rate limited second request shows Wait 60 seconds flash", %{conn: conn} do
      {tenant, candidate} = setup_tenant_and_candidate()

      conn1 = post(conn, ~p"/#{tenant.slug}/portal/login", %{"email" => candidate.email})
      assert redirected_to(conn1) == "/#{tenant.slug}/portal/verify"
      assert_received {:email, _}

      # Immediate second request should be rate limited
      conn2 = post(conn1, ~p"/#{tenant.slug}/portal/login", %{"email" => candidate.email})
      assert redirected_to(conn2) == "/#{tenant.slug}/portal/verify"

      assert Phoenix.Flash.get(conn2.assigns.flash, :error) ==
               "Wait 60 seconds before requesting another code"
    end

    test "unknown email still shows generic success (no enumeration)", %{conn: conn} do
      {tenant, _candidate} = setup_tenant_and_candidate()

      conn =
        post(conn, ~p"/#{tenant.slug}/portal/login", %{
          "email" => "unknown-#{System.unique_integer([:positive])}@test.com"
        })

      assert redirected_to(conn) == "/#{tenant.slug}/portal/verify"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) ==
               "Check your email for your login code"

      # Wait, previous tests may have sent emails, so we need to flush?
      assert_no_email_sent()
    end
  end
end
