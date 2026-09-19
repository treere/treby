defmodule TrebyWeb.DataPrivacyDownloadController do
  use TrebyWeb, :controller

  alias Treby.DataPrivacy.Requests

  def download(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    tenant = conn.assigns.current_tenant

    if is_nil(tenant) or is_nil(user) do
      conn |> put_status(403) |> text(gettext("Forbidden"))
    else
      case Requests.get_request(tenant.id, id) do
        nil ->
          conn |> put_status(404) |> text(gettext("Not found"))

        %Treby.DataPrivacy.DataPrivacyRequest{type: "erasure"} ->
          conn |> put_status(404) |> text(gettext("Not found"))

        request ->
          cond do
            request.status != "ready" ->
              conn |> put_status(410) |> text(gettext("Not ready or expired"))

            Treby.DataPrivacy.DataPrivacyRequest.expired?(request) ->
              conn |> put_status(410) |> text(gettext("Expired"))

            request.s3_key == nil ->
              conn |> put_status(410) |> text(gettext("No file"))

            true ->
              # Verify tenant-scoped key via Uploads.get_presigned_url (raises if not scoped)
              case Treby.Uploads.get_presigned_url(tenant.id, request.s3_key, expires_in: 3600) do
                {:ok, url} ->
                  Treby.Audit.log_event(
                    "data_privacy.export_downloaded",
                    "data_privacy_request",
                    request.id,
                    %{
                      tenant_id: tenant.id,
                      actor_id: user.id,
                      metadata: %{type: "export", scope: request.scope}
                    }
                  )

                  redirect(conn, external: url)

                {:error, reason} ->
                  conn |> put_status(500) |> text(inspect(reason))
              end
          end
      end
    end
  end
end
