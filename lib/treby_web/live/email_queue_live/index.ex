defmodule TrebyWeb.EmailQueueLive.Index do
  use TrebyWeb, :live_view

  alias Treby.EmailQueue

  @tabs ~w(queued sent failed cancelled)

  def mount(_params, session, socket) do
    current_user_id = session["user_id"]
    user = Treby.Accounts.get_user!(current_user_id)
    tab = "queued"

    socket =
      socket
      |> assign(:current_user, user)
      |> assign(:tab, tab)
      |> assign(:selected_ids, MapSet.new())
      |> assign(:edit_email, nil)
      |> assign(:edit_form, nil)
      |> assign(:page_title, "Email Queue")
      |> load_emails(user.tenant_id, tab)

    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    tab = params["tab"] || socket.assigns.tab
    tab = if tab in @tabs, do: tab, else: "queued"
    user = socket.assigns.current_user

    socket =
      socket
      |> assign(:tab, tab)
      |> assign(:selected_ids, MapSet.new())
      |> load_emails(user.tenant_id, tab)

    {:noreply, socket}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    tab = if tab in @tabs, do: tab, else: "queued"
    current_user = socket.assigns.current_user

    socket =
      socket
      |> assign(:tab, tab)
      |> assign(:selected_ids, MapSet.new())
      |> load_emails(current_user.tenant_id, tab)
      |> push_patch(to: ~p"/app/email-queue?tab=#{tab}")

    {:noreply, socket}
  end

  def handle_event("toggle_select", %{"id" => id}, socket) do
    selected = socket.assigns.selected_ids

    selected =
      if MapSet.member?(selected, id) do
        MapSet.delete(selected, id)
      else
        MapSet.put(selected, id)
      end

    {:noreply, assign(socket, :selected_ids, selected)}
  end

  def handle_event("select_all", _params, socket) do
    ids = Enum.map(socket.assigns.emails, & &1.id) |> MapSet.new()
    {:noreply, assign(socket, :selected_ids, ids)}
  end

  def handle_event("deselect_all", _params, socket) do
    {:noreply, assign(socket, :selected_ids, MapSet.new())}
  end

  def handle_event("open_edit", %{"id" => id}, socket) do
    email = EmailQueue.get_scheduled_email!(id)

    form =
      to_form(%{
        "subject" => email.subject,
        "body" => email.body || "",
        "scheduled_at_date" => format_date(email.scheduled_at),
        "scheduled_at_time" => format_time(email.scheduled_at),
        "jitter_minutes" => email.jitter_minutes || 0
      })

    {:noreply, assign(socket, edit_email: email, edit_form: form)}
  end

  def handle_event("close_edit", _params, socket) do
    {:noreply, assign(socket, edit_email: nil, edit_form: nil)}
  end

  def handle_event("save_edit", %{"scheduled_email" => params}, socket) do
    email = socket.assigns.edit_email

    date = params["scheduled_at_date"]
    time = params["scheduled_at_time"]

    scheduled_at =
      case DateTime.new(Date.from_iso8601!(date), Time.from_iso8601!(time), "Etc/UTC") do
        {:ok, dt} -> dt
        _ -> email.scheduled_at
      end

    attrs = %{
      subject: params["subject"],
      body: params["body"],
      scheduled_at: scheduled_at,
      jitter_minutes: String.to_integer(params["jitter_minutes"] || "0")
    }

    case EmailQueue.edit_scheduled_email(email, attrs) do
      {:ok, _updated} ->
        current_user = socket.assigns.current_user

        socket =
          socket
          |> put_flash(:info, "Email updated")
          |> assign(edit_email: nil, edit_form: nil)
          |> load_emails(current_user.tenant_id, socket.assigns.tab)

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update email")}
    end
  end

  def handle_event("send_now", %{"id" => id}, socket) do
    email = EmailQueue.get_scheduled_email!(id)
    EmailQueue.force_send(email)

    current_user = socket.assigns.current_user

    socket =
      socket
      |> put_flash(:info, "Email queued for immediate sending")
      |> load_emails(current_user.tenant_id, socket.assigns.tab)

    {:noreply, socket}
  end

  def handle_event("bulk_send_now", _params, socket) do
    ids = socket.assigns.selected_ids

    Enum.each(ids, fn id ->
      email = EmailQueue.get_scheduled_email!(id)
      EmailQueue.force_send(email)
    end)

    current_user = socket.assigns.current_user

    socket =
      socket
      |> put_flash(:info, "#{Enum.count(ids)} emails queued for sending")
      |> assign(:selected_ids, MapSet.new())
      |> load_emails(current_user.tenant_id, socket.assigns.tab)

    {:noreply, socket}
  end

  def handle_event("cancel", %{"id" => id}, socket) do
    email = EmailQueue.get_scheduled_email!(id)
    EmailQueue.cancel_scheduled_email(email)

    current_user = socket.assigns.current_user

    socket =
      socket
      |> put_flash(:info, "Email cancelled")
      |> load_emails(current_user.tenant_id, socket.assigns.tab)

    {:noreply, socket}
  end

  def handle_event("bulk_cancel", _params, socket) do
    ids = socket.assigns.selected_ids

    Enum.each(ids, fn id ->
      email = EmailQueue.get_scheduled_email!(id)
      EmailQueue.cancel_scheduled_email(email)
    end)

    current_user = socket.assigns.current_user

    socket =
      socket
      |> put_flash(:info, "#{Enum.count(ids)} emails cancelled")
      |> assign(:selected_ids, MapSet.new())
      |> load_emails(current_user.tenant_id, socket.assigns.tab)

    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    email = EmailQueue.get_scheduled_email!(id)
    EmailQueue.delete_scheduled_email(email)

    current_user = socket.assigns.current_user

    socket =
      socket
      |> put_flash(:info, "Email deleted")
      |> load_emails(current_user.tenant_id, socket.assigns.tab)

    {:noreply, socket}
  end

  def handle_event("retry", %{"id" => id}, socket) do
    email = EmailQueue.get_scheduled_email!(id)
    EmailQueue.retry_failed(email)

    current_user = socket.assigns.current_user

    socket =
      socket
      |> put_flash(:info, "Email scheduled for retry")
      |> load_emails(current_user.tenant_id, socket.assigns.tab)

    {:noreply, socket}
  end

  defp load_emails(socket, tenant_id, tab) do
    emails =
      case tab do
        "queued" -> EmailQueue.list_queued(tenant_id)
        "sent" -> EmailQueue.list_sent(tenant_id)
        "failed" -> EmailQueue.list_failed(tenant_id)
        "cancelled" -> EmailQueue.list_cancelled(tenant_id)
      end

    counts = %{
      queued: length(EmailQueue.list_queued(tenant_id)),
      sent: length(EmailQueue.list_sent(tenant_id)),
      failed: length(EmailQueue.list_failed(tenant_id)),
      cancelled: length(EmailQueue.list_cancelled(tenant_id))
    }

    assign(socket, emails: emails, counts: counts, tenant_id: tenant_id)
  end

  defp format_date(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d")
  defp format_date(_), do: ""

  defp format_time(%DateTime{} = dt), do: Calendar.strftime(dt, "%H:%M")
  defp format_time(_), do: ""

  defp format_datetime(%DateTime{} = dt), do: Calendar.strftime(dt, "%b %d, %Y %H:%M")
  defp format_datetime(_), do: ""

  defp email_type_label("compose"), do: "Compose"
  defp email_type_label("reply"), do: "Reply"
  defp email_type_label("bulk"), do: "Bulk"
  defp email_type_label("stage_change"), do: "Stage"
  defp email_type_label(_), do: "Email"
end
