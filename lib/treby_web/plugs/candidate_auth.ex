defmodule TrebyWeb.Plugs.CandidateAuth do
  @moduledoc """
  Plug for authenticating candidates via OTP session.

  Checks for a valid candidate session and loads the candidate and tenant.
  Redirects to the OTP request page if no valid session exists.
  Sessions expire after a limited lifetime (checked via `candidate_expires_at`).
  """

  import Plug.Conn
  alias Treby.Candidates.Candidate
  alias Treby.Tenants.Tenant
  alias Treby.Repo

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, "candidate_id") do
      nil ->
        redirect_to_login(conn)

      candidate_id ->
        if session_expired?(conn) do
          conn
          |> delete_session("candidate_id")
          |> delete_session("candidate_tenant_id")
          |> delete_session("candidate_expires_at")
          |> redirect_to_login()
        else
          case Repo.get(Candidate, candidate_id) do
            nil ->
              conn
              |> delete_session("candidate_id")
              |> redirect_to_login()

            candidate ->
              tenant = Repo.get!(Tenant, candidate.tenant_id)

              conn
              |> assign(:current_candidate, candidate)
              |> assign(:current_tenant, tenant)
          end
        end
    end
  end

  defp session_expired?(conn) do
    case get_session(conn, "candidate_expires_at") do
      nil ->
        true

      expires_at ->
        DateTime.compare(DateTime.from_unix!(expires_at), DateTime.utc_now()) == :lt
    end
  end

  defp redirect_to_login(conn) do
    # Extract tenant_slug from path if available
    case conn.path_params do
      %{"tenant_slug" => slug} ->
        conn
        |> Phoenix.Controller.put_flash(:error, "Please log in to access the portal")
        |> Phoenix.Controller.redirect(to: "/#{slug}/portal/login")
        |> halt()

      _ ->
        conn
        |> Phoenix.Controller.put_flash(:error, "Please log in to access the portal")
        |> Phoenix.Controller.redirect(to: "/")
        |> halt()
    end
  end
end
