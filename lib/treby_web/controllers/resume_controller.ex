defmodule TrebyWeb.ResumeController do
  use TrebyWeb, :controller

  alias Treby.Pipeline

  def show(conn, %{"id" => application_id}) do
    tenant = conn.assigns.current_tenant
    application = Pipeline.get_application!(tenant.id, application_id)

    case application.resume_url do
      nil ->
        conn
        |> put_flash(:error, "No resume available for this application")
        |> redirect(to: ~p"/app/candidates/#{application.candidate_id}")

      s3_key ->
        presigned_url = Treby.Uploads.get_presigned_url(s3_key, expires_in: 300)

        conn
        |> redirect(external: presigned_url)
    end
  end
end
