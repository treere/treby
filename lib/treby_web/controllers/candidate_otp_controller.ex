defmodule TrebyWeb.CandidateOtpController do
  use TrebyWeb, :controller

  alias Treby.CandidatePortal
  alias Treby.Candidates
  alias Treby.Notifications.Email, as: NotificationEmail
  alias Treby.Tenants

  @doc """
  Processes the OTP request. Generates a code and emails it to the candidate.
  Always shows the same success message to prevent email enumeration.
  """
  def create(conn, %{"tenant_slug" => slug, "email" => email}) do
    tenant = Tenants.get_tenant_by_slug!(slug)
    email = email |> String.trim() |> String.downcase()

    result =
      case Candidates.list_candidates(tenant.id, %{search: email}) do
        [candidate | _] ->
          case CandidatePortal.generate_otp(candidate) do
            {:ok, code} -> {:ok, candidate, code}
            {:error, :rate_limited} -> {:error, :rate_limited}
            other -> other
          end

        _ ->
          :not_found
      end

    case result do
      {:ok, candidate, code} ->
        candidate
        |> NotificationEmail.otp_email(tenant, code)
        |> Treby.Mailer.deliver()

        conn
        |> put_session("otp_email", email)
        |> put_flash(:info, gettext("Check your email for your login code"))
        |> redirect(to: "/#{slug}/portal/verify")

      {:error, :rate_limited} ->
        conn
        |> put_session("otp_email", email)
        |> put_flash(:error, gettext("Wait 60 seconds before requesting another code"))
        |> redirect(to: "/#{slug}/portal/verify")

      _ ->
        conn
        |> put_session("otp_email", email)
        |> put_flash(:info, gettext("Check your email for your login code"))
        |> redirect(to: "/#{slug}/portal/verify")
    end
  end

  @doc """
  Verifies the OTP code and creates a candidate session with a limited lifetime.
  """
  def verify(conn, %{"tenant_slug" => slug} = params) do
    email = get_session(conn, "otp_email") || Map.get(params, "email", "")
    tenant = Tenants.get_tenant_by_slug!(slug)

    case Candidates.list_candidates(tenant.id, %{search: email}) do
      [candidate | _] ->
        code = Map.get(params, "code", "")

        case CandidatePortal.verify_otp(candidate, code) do
          {:ok, candidate, tenant} ->
            expires_at =
              DateTime.utc_now()
              |> DateTime.add(CandidatePortal.session_lifetime_hours(), :hour)

            conn
            |> put_session("candidate_id", candidate.id)
            |> put_session("candidate_tenant_id", tenant.id)
            |> put_session("candidate_expires_at", DateTime.to_unix(expires_at))
            |> delete_session("otp_email")
            |> redirect(to: "/#{slug}/portal")

          {:error, _reason} ->
            CandidatePortal.record_failed_otp_attempt(candidate, code)

            conn
            |> put_flash(:error, gettext("Invalid or expired code. Please try again."))
            |> redirect(to: "/#{slug}/portal/verify")
        end

      _ ->
        conn
        |> put_flash(:error, gettext("Invalid or expired code. Please try again."))
        |> redirect(to: "/#{slug}/portal/verify")
    end
  end
end
