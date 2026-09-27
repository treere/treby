defmodule TrebyWeb.CandidatePortalLive.PortalHelpers do
  @moduledoc """
  Shared mount prefix for candidate portal LiveViews: tenant-from-slug
  resolution plus the wrong-workspace guard. Page-specific assigns stay
  in each LiveView; only the identical guard branches live here.
  """

  use Gettext, backend: TrebyWeb.Gettext

  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [put_flash: 3, redirect: 2]

  @doc """
  Authenticated portal mount. Returns `{:ok, tenant, candidate}` or
  `{:redirect, socket}` with the wrong-workspace flash. `redirect_to`
  is the page suffix appended after the candidate's real portal root.
  """
  def mount_portal(socket, session, slug, redirect_to) do
    Treby.Repo.put_tenant_id_from_session(session)
    candidate = Treby.Repo.get!(Treby.Candidates.Candidate, session["candidate_id"])
    tenant = Treby.Tenants.get_tenant_by_slug!(slug)

    if tenant.id != candidate.tenant_id do
      real_tenant = Treby.Repo.get!(Treby.Tenants.Tenant, candidate.tenant_id)

      {:redirect,
       socket
       |> put_flash(:error, gettext("Wrong workspace. Redirected to your portal."))
       |> redirect(to: "/#{real_tenant.slug}" <> redirect_to)}
    else
      {:ok, tenant, candidate}
    end
  end

  @doc """
  Pre-auth portal mount (request link, OTP verify): slug lookup plus
  tenant scoping, assigning `:tenant`.
  """
  def mount_public_portal(socket, slug) do
    tenant = Treby.Tenants.get_tenant_by_slug!(slug)
    Treby.Repo.put_tenant_id(tenant.id)

    {:ok, assign(socket, :tenant, tenant)}
  end
end
