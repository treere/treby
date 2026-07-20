defmodule TrebyWeb.GoogleAuthController do
  use TrebyWeb, :controller

  alias Treby.Calendar

  @google_auth_url "https://accounts.google.com/o/oauth2/v2/auth"
  @google_token_url "https://oauth2.googleapis.com/token"
  @google_userinfo_url "https://www.googleapis.com/oauth2/v2/userinfo"
  @calendar_scope "https://www.googleapis.com/auth/calendar"

  def new(conn, _params) do
    client_id = Application.get_env(:treby, :google_client_id)
    redirect_uri = google_redirect_uri(conn)

    params =
      URI.encode_query(%{
        client_id: client_id,
        redirect_uri: redirect_uri,
        response_type: "code",
        scope: @calendar_scope,
        access_type: "offline",
        prompt: "consent"
      })

    redirect(conn, external: "#{@google_auth_url}?#{params}")
  end

  def callback(%{assigns: %{current_user: user, current_tenant: tenant}} = conn, %{"code" => code}) do
    client_id = Application.get_env(:treby, :google_client_id)
    client_secret = Application.get_env(:treby, :google_client_secret)
    redirect_uri = google_redirect_uri(conn)

    token_body = %{
      code: code,
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: redirect_uri,
      grant_type: "authorization_code"
    }

    case Req.post(@google_token_url, form: token_body) do
      {:ok, %{status: 200, body: token_resp}} ->
        userinfo_req = Req.new(base_url: @google_userinfo_url)

        case Req.get(userinfo_req, params: [access_token: token_resp["access_token"]]) do
          {:ok, %{status: 200, body: userinfo}} ->
            expires_at = DateTime.utc_now() |> DateTime.add(token_resp["expires_in"], :second)

            token_data = %{
              access_token: token_resp["access_token"],
              refresh_token: token_resp["refresh_token"],
              expires_at: expires_at,
              email: userinfo["email"]
            }

            case Calendar.connect_google_user(user.id, tenant.id, token_data) do
              {:ok, _} ->
                conn
                |> put_flash(:info, "Google Calendar connected successfully")
                |> redirect(to: ~p"/app/settings/calendar")

              {:error, _} ->
                conn
                |> put_flash(:error, "Failed to save calendar connection")
                |> redirect(to: ~p"/app/settings/calendar")
            end

          _ ->
            conn
            |> put_flash(:error, "Failed to get user info from Google")
            |> redirect(to: ~p"/app/settings/calendar")
        end

      _ ->
        conn
        |> put_flash(:error, "Failed to exchange authorization code")
        |> redirect(to: ~p"/app/settings/calendar")
    end
  end

  defp google_redirect_uri(conn) do
    URI.to_string(%{
      scheme: to_string(conn.scheme),
      host: conn.host,
      port: conn.port,
      path: "/auth/google/callback"
    })
  end
end
