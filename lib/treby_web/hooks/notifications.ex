defmodule TrebyWeb.Hooks.Notifications do
  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [attach_hook: 4, connected?: 1]

  alias Treby.Notifications.Inbox

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def on_mount(:default, _params, _session, socket) do
    socket =
      if socket.assigns[:current_user] && socket.assigns[:current_tenant] do
        user = socket.assigns.current_user
        tenant = socket.assigns.current_tenant

        if connected?(socket) do
          Phoenix.PubSub.subscribe(Treby.PubSub, "notifications:#{user.id}")
        end

        count = Inbox.unread_count(user.id, tenant.id)

        recent = Inbox.list_for_user(user.id, tenant.id, filter: :unread, limit: 5)

        socket
        |> assign(:notification_unread_count, count)
        |> assign(:notification_recent, recent)
        |> assign(:notification_toast, nil)
        |> attach_hook(:notifications_handle_event, :handle_event, fn
          "mark_all_read", _params, socket ->
            if socket.view == TrebyWeb.NotificationsLive do
              {:cont, socket}
            else
              if socket.assigns[:current_user] && socket.assigns[:current_tenant] do
                Inbox.mark_all_read(
                  socket.assigns.current_user.id,
                  socket.assigns.current_tenant.id
                )

                count = 0
                recent = []

                {:halt,
                 socket
                 |> assign(:notification_unread_count, count)
                 |> assign(:notification_recent, recent)}
              else
                {:cont, socket}
              end
            end

          "mark_read", %{"id" => id}, socket ->
            if socket.view == TrebyWeb.NotificationsLive do
              {:cont, socket}
            else
              if socket.assigns[:current_user] && socket.assigns[:current_tenant] do
                Inbox.mark_read(
                  id,
                  socket.assigns.current_user.id,
                  socket.assigns.current_tenant.id
                )

                recent =
                  Enum.reject(socket.assigns[:notification_recent] || [], fn n -> n.id == id end)

                count = max(0, (socket.assigns[:notification_unread_count] || 1) - 1)

                {:halt,
                 socket
                 |> assign(:notification_unread_count, count)
                 |> assign(:notification_recent, recent)}
              else
                {:cont, socket}
              end
            end

          "toast_view", %{"id" => id, "link" => link}, socket ->
            if socket.assigns[:current_user] && socket.assigns[:current_tenant] do
              Inbox.mark_read(
                id,
                socket.assigns.current_user.id,
                socket.assigns.current_tenant.id
              )

              recent =
                Enum.reject(socket.assigns[:notification_recent] || [], fn n -> n.id == id end)

              count = max(0, (socket.assigns[:notification_unread_count] || 1) - 1)

              {:halt,
               socket
               |> assign(:notification_unread_count, count)
               |> assign(:notification_recent, recent)
               |> assign(:notification_toast, nil)
               |> Phoenix.LiveView.push_navigate(to: link)}
            else
              {:cont, socket}
            end

          "toast_dismiss", _params, socket ->
            {:halt, assign(socket, :notification_toast, nil)}

          _event, _params, socket ->
            {:cont, socket}
        end)
        |> attach_hook(:notifications_handle_info, :handle_info, fn
          {:new_notification, notification}, socket ->
            count = (socket.assigns[:notification_unread_count] || 0) + 1
            recent = [notification | socket.assigns[:notification_recent] || []] |> Enum.take(5)

            {:halt,
             socket
             |> assign(:notification_unread_count, count)
             |> assign(:notification_recent, recent)
             |> assign(:notification_toast, notification)
             |> Phoenix.LiveView.put_flash(:info, notification.title)}

          _msg, socket ->
            {:cont, socket}
        end)
      else
        socket
        |> assign(:notification_unread_count, 0)
        |> assign(:notification_recent, [])
        |> assign(:notification_toast, nil)
      end

    {:cont, socket}
  end
end
