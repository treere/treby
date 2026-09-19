defmodule TrebyWeb.SettingsLive.Language do
  use TrebyWeb, :live_view

  alias Treby.Accounts

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)

    {user, tenant, membership} =
      cond do
        socket.assigns[:current_user] && socket.assigns[:current_tenant] ->
          {socket.assigns.current_user, socket.assigns.current_tenant,
           socket.assigns[:current_membership]}

        session["user_id"] && session["tenant_id"] ->
          u = Accounts.get_user!(session["user_id"])
          t = Treby.Tenants.get_tenant!(session["tenant_id"])
          m = Treby.Memberships.get_membership(u.id, t.id)
          {u, t, m}

        session["user_id"] ->
          u = Accounts.get_user!(session["user_id"])

          case Treby.Memberships.list_tenants_for_user(u.id) do
            [%{tenant: t, membership: m} | _] -> {u, t, m}
            [%{tenant: t} | _] -> {u, t, nil}
            [] -> {u, nil, nil}
          end

        true ->
          {nil, nil, nil}
      end

    user = user || Accounts.get_user!(session["user_id"])
    changeset = Accounts.User.locale_changeset(user, %{})

    {:ok,
     socket
     |> assign(settings_active: true)
     |> assign(current_user: user, current_tenant: tenant, current_membership: membership)
     |> assign(form: to_form(changeset))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <TrebyWeb.SettingsLayout.settings_shell
          current_tenant={assigns[:current_tenant]}
          current_membership={assigns[:current_membership]}
          active_key={:language}
        >
          <.button
            variant="ghost"
            navigate={
              if @current_tenant, do: "/#{@current_tenant.slug}/app/settings", else: ~p"/app/settings"
            }
            size="sm"
          >
            &larr; {gettext("Back to Settings")}
          </.button>

          <h1 class="mt-4 text-2xl font-bold text-zinc-900 dark:text-zinc-100">
            {gettext("Language")}
          </h1>
          <p class="mt-2 text-zinc-500 dark:text-zinc-400">
            {gettext("Set your preferred language")}
          </p>

          <.form for={@form} id="language-form" phx-submit="save" class="mt-8">
            <.input
              field={@form[:locale]}
              type="select"
              label={gettext("Language")}
              options={[{"English", "en"}, {"Italiano", "it"}]}
            />

            <div class="mt-6">
              <.button variant="primary" type="submit" loading_text={gettext("Saving...")}>
                {gettext("Save")}
              </.button>
            </div>
          </.form>
        </TrebyWeb.SettingsLayout.settings_shell>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("save", %{"user" => %{"locale" => locale}}, socket) do
    case Accounts.update_locale(socket.assigns.current_user, locale) do
      {:ok, user} ->
        Gettext.put_locale(TrebyWeb.Gettext, locale)

        {:noreply,
         socket
         |> assign(current_user: user, locale: locale)
         |> put_flash(:info, gettext("Language updated successfully"))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(form: to_form(changeset))
         |> put_flash(:error, gettext("Please review the errors below"))}
    end
  end
end
