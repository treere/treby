defmodule TrebyWeb.Plugs.WebhookVerification do
  @moduledoc """
  Plug that verifies inbound webhook signatures from Postmark or SendGrid.

  Supports:
  - Postmark: X-Postmark-Signature header (SHA256 of raw body, base64-encoded)
  - SendGrid: X-Twilio-Email-Event-Webhook-Signature header (HMAC-SHA256)

  Configure the secret via `WEBHOOK_SECRET` environment variable.
  If no secret is configured, verification is skipped (dev convenience).
  """

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    secret = System.get_env("WEBHOOK_SECRET")

    if secret do
      case Plug.Conn.read_body(conn) do
        {:ok, body, conn} ->
          case verify_signature(conn, body, secret) do
            :ok ->
              conn

            :error ->
              conn
              |> Plug.Conn.put_resp_content_type("text/plain")
              |> Plug.Conn.send_resp(401, "Unauthorized")
              |> Plug.Conn.halt()
          end

        {:error, _} ->
          conn
          |> Plug.Conn.put_resp_content_type("text/plain")
          |> Plug.Conn.send_resp(400, "Bad Request")
          |> Plug.Conn.halt()
      end
    else
      conn
    end
  end

  defp verify_signature(conn, body, secret) do
    cond do
      # Postmark: X-Postmark-Signature (SHA256 of body)
      postmark_sig = get_req_header_value(conn, "x-postmark-signature") ->
        computed = :crypto.hash(:sha256, body) |> Base.encode64()
        secure_compare(postmark_sig, computed)

      # SendGrid: X-Twilio-Email-Event-Webhook-Signature (HMAC-SHA256)
      sendgrid_sig = get_req_header_value(conn, "x-twilio-email-event-webhook-signature") ->
        timestamp = get_req_header_value(conn, "x-twilio-email-event-webhook-timestamp") || ""
        payload = timestamp <> body
        computed = :crypto.mac(:hmac, :sha256, secret, payload) |> Base.encode64()
        secure_compare(sendgrid_sig, computed)

      # No signature header — reject if secret is configured
      true ->
        false
    end
    |> case do
      true -> :ok
      false -> :error
    end
  end

  defp get_req_header_value(conn, header) do
    case Plug.Conn.get_req_header(conn, header) do
      [value | _] -> value
      _ -> nil
    end
  end

  defp secure_compare(a, b) when byte_size(a) == byte_size(b) do
    Plug.Crypto.secure_compare(a, b) == 0
  end

  defp secure_compare(_, _), do: false
end
