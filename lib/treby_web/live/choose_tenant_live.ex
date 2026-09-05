defmodule TrebyWeb.ChooseTenantLive do
  use TrebyWeb, :live_view

  def mount(_params, %{"user_id" => user_id} = _session, socket) do
    user = Treby.Repo.get!(Treby.Accounts.User, user_id)
    tenants = Treby.Memberships.list_tenants_for_user(user_id)

    case tenants do
      [%{tenant: tenant}] ->
        {:ok, push_navigate(socket, to: "/#{tenant.slug}/app")}

      _ ->
        {:ok,
         socket
         |> assign(:current_user, user)
         |> assign(:current_tenant, nil)
         |> assign(:current_membership, nil)
         |> assign(:available_tenants, tenants)
         |> assign(:tenants, tenants)}
    end
  end

  def mount(_params, _session, socket) do
    {:ok, push_navigate(socket, to: "/login")}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_user}
      current_tenant={@current_tenant}
      current_membership={@current_membership}
      available_tenants={@available_tenants}
    >
      <div class="max-w-xl mx-auto py-12">
        <h1 class="text-2xl font-bold mb-6">{gettext("Choose workspace")}</h1>
        <div id="workspace-picker" class="space-y-3">
          <div :for={%{tenant: tenant, role: role} <- @tenants} id={"workspace-#{tenant.slug}"}>
            <.link
              navigate={"/#{tenant.slug}/app"}
              class="flex justify-between items-center p-4 border rounded-lg hover:bg-zinc-50 dark:bg-zinc-800"
            >
              <div>
                <div class="font-medium">{tenant.name}</div>
                <div class="text-sm text-zinc-500 dark:text-zinc-400">{tenant.slug}</div>
              </div>
              <span class="inline-flex items-center rounded-full border text-xs font-medium bg-zinc-100 text-zinc-700 border-zinc-200 px-2 py-0.5">{role}</span>
            </.link>
          </div>
        </div>

        <div class="mt-8 border-t pt-6">
          <h2 class="font-medium mb-3">{gettext("Create new company")}</h2>
          <.form for={%{}} action={~p"/tenants"} method="post" id="create-tenant-form">
            <div class="flex gap-2">
              <input
                name="tenant[name]"
                placeholder={gettext("Company name")}
                class="input input-bordered flex-1"
                required
              />
              <button
                type="submit"
                class="inline-flex items-center justify-center rounded-lg bg-orange-600 px-4 py-2 text-sm font-medium text-white hover:bg-orange-700 shadow-sm"
              >{gettext("Create")}</button>
            </div>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
