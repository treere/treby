defmodule TrebyWeb.Plugs.CandidateAuth do
  @moduledoc """
  Plug for authenticating candidates via magic link session.

  Checks for a valid candidate session and loads the candidate and tenant.
  Redirects to the magic link request page if no valid session exists.
  """

  import Plug.Conn
  alias Treby.Candidates.Candidate
  alias Treby.Tenants.Tenant
  alias Treby.Repo

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, "candidate_id") do
      nil ->
        redirect_to_magic_link(conn)

      candidate_id ->
        case Repo.get(Candidate, candidate_id) do
          nil ->
            conn
            |> delete_session("candidate_id")
            |> redirect_to_magic_link()

          candidate ->
            tenant = Repo.get!(Tenant, candidate.tenant_id)

            conn
            |> assign(:current_candidate, candidate)
            |> assign(:current_tenant, tenant)
        end
    end
  end

  defp redirect_to_magic_link(conn) do
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
