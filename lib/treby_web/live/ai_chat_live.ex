defmodule TrebyWeb.AiChatLive do
  use TrebyWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, gettext("Assistant"))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_user}
      current_tenant={@current_tenant}
      locale={@locale}
      notification_unread_count={assigns[:notification_unread_count] || 0}
      notification_recent={assigns[:notification_recent] || []}
      available_tenants={assigns[:available_tenants] || []}
      assistant={false}
    >
      <.live_component
        module={TrebyWeb.AiChatWidget}
        id="ai-chat"
        variant={:page}
        current_user={@current_user}
        current_tenant={@current_tenant}
      />
    </Layouts.app>
    """
  end
end
