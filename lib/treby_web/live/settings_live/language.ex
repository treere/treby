defmodule TrebyWeb.SettingsLive.Language do
  use TrebyWeb, :live_view

  alias Treby.Accounts

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    changeset = Accounts.User.locale_changeset(user, %{})

    {:ok,
     socket
     |> assign(current_user: user)
     |> assign(form: to_form(changeset))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8 max-w-2xl">
        <.link navigate={~p"/app/settings"} class="text-sm text-blue-600 hover:text-blue-500">
          ← {gettext("Settings")}
        </.link>

        <h1 class="mt-4 text-2xl font-bold">{gettext("Language")}</h1>
        <p class="mt-2 text-gray-600">{gettext("Set your preferred language")}</p>

        <.form for={@form} id="language-form" phx-submit="save" class="mt-8">
          <.input
            field={@form[:locale]}
            type="select"
            label={gettext("Language")}
            options={[{"English", "en"}, {"Italiano", "it"}]}
          />

          <div class="mt-6">
            <.button type="submit" phx-disable-with="Saving...">
              {gettext("Save")}
            </.button>
          </div>
        </.form>
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
         |> put_flash(:info, "Language updated successfully")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
