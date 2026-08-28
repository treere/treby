defmodule TrebyWeb.MessagesQueueLive.Index do
  use TrebyWeb, :live_view

  alias Treby.ScheduledMessages

  @tabs ~w(scheduled sent failed cancelled)

  def mount(_params, session, socket) do
    current_user_id = session["user_id"]
    user = Treby.Accounts.get_user!(current_user_id)
    tab = "scheduled"

    socket =
      socket
      |> assign(:current_user, user)
      |> assign(:tab, tab)
      |> assign(:selected_ids, MapSet.new())
      |> assign(:edit_message, nil)
      |> assign(:edit_form, nil)
      |> assign(:page_title, "Message Queue")
      |> load_messages(user.tenant_id, tab)

    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    tab = params["tab"] || socket.assigns.tab
    tab = if tab in @tabs, do: tab, else: "scheduled"
    user = socket.assigns.current_user

    socket =
      socket
      |> assign(:tab, tab)
      |> assign(:selected_ids, MapSet.new())
      |> load_messages(user.tenant_id, tab)

    {:noreply, socket}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    tab = if tab in @tabs, do: tab, else: "scheduled"
    current_user = socket.assigns.current_user

    socket =
      socket
      |> assign(:tab, tab)
      |> assign(:selected_ids, MapSet.new())
      |> load_messages(current_user.tenant_id, tab)
      |> push_patch(to: ~p"/app/messages-queue?tab=#{tab}")

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
    ids = Enum.map(socket.assigns.messages, & &1.id) |> MapSet.new()
    {:noreply, assign(socket, :selected_ids, ids)}
  end

  def handle_event("deselect_all", _params, socket) do
    {:noreply, assign(socket, :selected_ids, MapSet.new())}
  end

  def handle_event("open_edit", %{"id" => id}, socket) do
    message = ScheduledMessages.get_scheduled_message!(id)

    form =
      to_form(%{
        "body" => message.body,
        "scheduled_at_date" => format_date(message.send_at),
        "scheduled_at_time" => format_time(message.send_at)
      })

    {:noreply, assign(socket, edit_message: message, edit_form: form)}
  end

  def handle_event("close_edit", _params, socket) do
    {:noreply, assign(socket, edit_message: nil, edit_form: nil)}
  end

  def handle_event("save_edit", %{"scheduled_message" => params}, socket) do
    message = socket.assigns.edit_message

    date = params["scheduled_at_date"]
    time = params["scheduled_at_time"]

    case parse_time(time) do
      {:ok, parsed_time} ->
        do_save_edit(socket, message, date, parsed_time, params)

      :error ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid time format. Use HH:MM, e.g. 23:49.")
         |> assign(edit_form: to_form(params))}
    end
  end

  def handle_event("send_now", %{"id" => id}, socket) do
    message = ScheduledMessages.get_scheduled_message!(id)
    ScheduledMessages.force_send(message)

    current_user = socket.assigns.current_user

    socket =
      socket
      |> put_flash(:info, "Message queued for immediate posting")
      |> load_messages(current_user.tenant_id, socket.assigns.tab)

    {:noreply, socket}
  end

  def handle_event("bulk_send_now", _params, socket) do
    ids = socket.assigns.selected_ids

    Enum.each(ids, fn id ->
      message = ScheduledMessages.get_scheduled_message!(id)
      ScheduledMessages.force_send(message)
    end)

    current_user = socket.assigns.current_user

    socket =
      socket
      |> put_flash(:info, "#{Enum.count(ids)} messages queued for posting")
      |> assign(:selected_ids, MapSet.new())
      |> load_messages(current_user.tenant_id, socket.assigns.tab)

    {:noreply, socket}
  end

  def handle_event("cancel", %{"id" => id}, socket) do
    message = ScheduledMessages.get_scheduled_message!(id)
    ScheduledMessages.cancel(message)

    current_user = socket.assigns.current_user

    socket =
      socket
      |> put_flash(:info, "Message cancelled")
      |> load_messages(current_user.tenant_id, socket.assigns.tab)

    {:noreply, socket}
  end

  def handle_event("bulk_cancel", _params, socket) do
    ids = socket.assigns.selected_ids

    Enum.each(ids, fn id ->
      message = ScheduledMessages.get_scheduled_message!(id)
      ScheduledMessages.cancel(message)
    end)

    current_user = socket.assigns.current_user

    socket =
      socket
      |> put_flash(:info, "#{Enum.count(ids)} messages cancelled")
      |> assign(:selected_ids, MapSet.new())
      |> load_messages(current_user.tenant_id, socket.assigns.tab)

    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    message = ScheduledMessages.get_scheduled_message!(id)
    ScheduledMessages.delete(message)

    current_user = socket.assigns.current_user

    socket =
      socket
      |> put_flash(:info, "Message deleted")
      |> load_messages(current_user.tenant_id, socket.assigns.tab)

    {:noreply, socket}
  end

  def handle_event("retry", %{"id" => id}, socket) do
    message = ScheduledMessages.get_scheduled_message!(id)
    ScheduledMessages.retry_failed(message)

    current_user = socket.assigns.current_user

    socket =
      socket
      |> put_flash(:info, "Message scheduled for retry")
      |> load_messages(current_user.tenant_id, socket.assigns.tab)

    {:noreply, socket}
  end

  defp load_messages(socket, tenant_id, tab) do
    messages =
      case tab do
        "scheduled" -> ScheduledMessages.list_scheduled(tenant_id)
        "sent" -> ScheduledMessages.list_sent(tenant_id)
        "failed" -> ScheduledMessages.list_failed(tenant_id)
        "cancelled" -> ScheduledMessages.list_cancelled(tenant_id)
      end

    counts = %{
      scheduled: length(ScheduledMessages.list_scheduled(tenant_id)),
      sent: length(ScheduledMessages.list_sent(tenant_id)),
      failed: length(ScheduledMessages.list_failed(tenant_id)),
      cancelled: length(ScheduledMessages.list_cancelled(tenant_id))
    }

    assign(socket, messages: messages, counts: counts, tenant_id: tenant_id)
  end

  defp format_date(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d")
  defp format_date(_), do: ""

  defp format_time(%DateTime{} = dt), do: Calendar.strftime(dt, "%H:%M")
  defp format_time(_), do: ""

  defp parse_time(time) when is_binary(time) do
    normalized = if String.length(time) == 5, do: time <> ":00", else: time

    case Time.from_iso8601(normalized) do
      {:ok, parsed} -> {:ok, parsed}
      _ -> :error
    end
  end

  defp parse_time(_), do: :error

  defp do_save_edit(socket, message, date, time, params) do
    send_at =
      case DateTime.new(Date.from_iso8601!(date), time, "Etc/UTC") do
        {:ok, dt} -> dt
        _ -> message.send_at
      end

    attrs = %{
      body: params["body"],
      send_at: send_at
    }

    case ScheduledMessages.edit(message, attrs) do
      {:ok, _updated} ->
        current_user = socket.assigns.current_user

        socket =
          socket
          |> put_flash(:info, "Message updated")
          |> assign(edit_message: nil, edit_form: nil)
          |> load_messages(current_user.tenant_id, socket.assigns.tab)

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update message")}
    end
  end

  defp format_datetime(%DateTime{} = dt), do: Calendar.strftime(dt, "%b %d, %Y %H:%M")
  defp format_datetime(_), do: ""

  defp message_type_label("templated"), do: "Templated"
  defp message_type_label("bulk"), do: "Bulk"
  defp message_type_label("text"), do: "Text"
  defp message_type_label(_), do: "Message"
end
