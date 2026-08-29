defmodule TrebyWeb.CandidatePortalLogoutController do
  use TrebyWeb, :controller

  @doc """
  Ends the candidate session and redirects to the portal login page.
  """
  def delete(conn, %{"tenant_slug" => slug}) do
    conn
    |> delete_session("candidate_id")
    |> delete_session("candidate_tenant_id")
    |> delete_session("candidate_expires_at")
    |> put_flash(:info, gettext("You have been logged out"))
    |> redirect(to: "/#{slug}/portal/login")
  end
end
