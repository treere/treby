defmodule TrebyWeb.MagicLinkController do
  use TrebyWeb, :controller

  alias Treby.CandidatePortal
  alias Treby.Candidates
  alias Treby.Notifications.Email, as: NotificationEmail
  alias Treby.Tenants

  @doc """
  Shows the magic link request form.
  """
  def new(conn, %{"tenant_slug" => slug}) do
    tenant = Tenants.get_tenant_by_slug!(slug)
    render(conn, "new.html", tenant: tenant)
  end

  @doc """
  Processes the magic link request. Sends an email with the link.
  Always shows success message to prevent email enumeration.
  """
  def create(conn, %{"tenant_slug" => slug, "email" => email}) do
    tenant = Tenants.get_tenant_by_slug!(slug)

    case Candidates.list_candidates(tenant.id, %{search: email}) do
      [candidate | _] ->
        case CandidatePortal.generate_magic_link_token(candidate) do
          {:ok, raw_token} ->
            url = "/#{slug}/c/#{raw_token}"

            email =
              NotificationEmail.magic_link_email(candidate, tenant, url)

            Treby.Mailer.deliver(email)

            conn
            |> put_flash(:info, "Check your email for a login link")
            |> redirect(to: "/#{slug}/portal")

          {:error, _changeset} ->
            conn
            |> put_flash(:error, "Something went wrong. Please try again.")
            |> redirect(to: "/#{slug}/portal")
        end

      _ ->
        # Always show success to prevent email enumeration
        conn
        |> put_flash(:info, "Check your email for a login link")
        |> redirect(to: "/#{slug}/portal")
    end
  end

  @doc """
  Validates the magic link token and creates a session.
  """
  def show(conn, %{"tenant_slug" => slug, "token" => token}) do
    case CandidatePortal.validate_magic_link_token(token) do
      {:ok, candidate, tenant} ->
        conn
        |> put_session("candidate_id", candidate.id)
        |> put_session("candidate_tenant_id", tenant.id)
        |> redirect(to: "/#{slug}/portal")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "This link is invalid or has expired. Please request a new one.")
        |> redirect(to: "/#{slug}/portal")
    end
  end
end
