defmodule TrebyWeb.EmailWebhookController do
  use TrebyWeb, :controller

  alias Treby.EmailThreads
  alias Treby.Candidates.Candidate
  alias Treby.Repo

  def create(conn, params) do
    # Parse Postmark/SendGrid payload
    case parse_webhook_payload(params) do
      {:ok, %{from: from, subject: subject, body: body, html_body: html_body}} ->
        # Find candidate by email
        case find_candidate_by_email(from) do
          {:ok, candidate} ->
            # Create or append to thread
            case EmailThreads.create_inbound_email(%{
                   from_address: from,
                   to_address: extract_to_address(params),
                   subject: subject,
                   body: body,
                   html_body: html_body,
                   candidate_id: candidate.id,
                   tenant_id: candidate.tenant_id
                 }) do
              {:ok, _message} ->
                send_resp(conn, 200, "OK")

              _ ->
                send_resp(conn, 200, "OK")
            end

          :not_found ->
            # Still return 200 to webhook provider
            send_resp(conn, 200, "OK")
        end

      {:error, _reason} ->
        send_resp(conn, 200, "OK")
    end
  end

  defp parse_webhook_payload(%{"From" => from, "Subject" => subject} = params) do
    # Postmark format
    body = params["TextBody"] || params["HtmlBody"] || ""
    html_body = params["HtmlBody"]

    {:ok,
     %{
       from: extract_email(from),
       subject: subject,
       body: body,
       html_body: html_body
     }}
  end

  defp parse_webhook_payload(%{"from" => from, "subject" => subject} = params) do
    # SendGrid format
    body = params["text"] || params["html"] || ""
    html_body = params["html"]

    {:ok,
     %{
       from: extract_email(from),
       subject: subject,
       body: body,
       html_body: html_body
     }}
  end

  defp parse_webhook_payload(_), do: {:error, "Unknown webhook format"}

  defp extract_email(address) when is_binary(address) do
    case Regex.run(~r/<(.+?)>/, address) do
      [_, email] -> email
      _ -> address |> String.trim()
    end
  end

  defp extract_email(_), do: ""

  defp extract_to_address(%{"To" => to}), do: extract_email(to)
  defp extract_to_address(%{"to" => to}), do: extract_email(to)
  defp extract_to_address(_), do: ""

  defp find_candidate_by_email(email) do
    case Repo.get_by(Candidate, email: email) do
      nil -> :not_found
      candidate -> {:ok, candidate}
    end
  end
end
