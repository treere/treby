defmodule TrebyWeb.DashboardLive do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants}

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])

    {:ok, assign(socket, current_user: user, current_tenant: tenant)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <h1 class="text-2xl font-bold">Dashboard</h1>
        <p class="mt-2 text-gray-600">Welcome, {@current_user.name}!</p>
        <p class="text-gray-600">Company: {@current_tenant.name}</p>
      </div>
    </Layouts.app>
    """
  end
end
