defmodule TrebyWeb.Plugs.DataPrivacyGraceBlock do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    tenant = conn.assigns[:current_tenant]
    membership = conn.assigns[:current_membership]

    if tenant && tenant.settings && tenant.settings["data_privacy_pending_erasure"] do
      grace = tenant.settings["data_privacy_pending_erasure"]

      # Allow admins to access Data & Privacy page to cancel
      path = conn.request_path || ""

      if (String.contains?(path, "/settings/data-privacy") and membership) &&
           membership.role == "admin" do
        conn
      else
        conn
        |> Phoenix.Controller.put_flash(
          :error,
          "This workspace has a pending Data & Privacy erasure (grace until #{grace}). Contact an admin to cancel at Settings → Data & Privacy."
        )
        |> Phoenix.Controller.redirect(to: "/#{tenant.slug}/app/settings/data-privacy")
        |> halt()
      end
    else
      conn
    end
  end
end
