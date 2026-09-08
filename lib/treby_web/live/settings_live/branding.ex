defmodule TrebyWeb.SettingsLive.Branding do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Careers}
  alias Treby.Careers.CareerPage

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)

    {user, tenant} =
      cond do
        socket.assigns[:current_user] && socket.assigns[:current_tenant] ->
          {socket.assigns.current_user, socket.assigns.current_tenant}

        session["user_id"] && session["tenant_id"] ->
          {Accounts.get_user!(session["user_id"]), Tenants.get_tenant!(session["tenant_id"])}

        session["user_id"] ->
          u = Accounts.get_user!(session["user_id"])

          case Treby.Memberships.list_tenants_for_user(u.id) do
            [%{tenant: t} | _] -> {u, t}
            [] -> {u, nil}
          end

        true ->
          {nil, nil}
      end

    career_page =
      Careers.get_career_page_by_tenant(tenant.id) ||
        %CareerPage{tenant_id: tenant.id, primary_color: "#3b82f6"}

    form = to_form(Careers.change_career_page(career_page))

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(career_page: career_page)
     |> assign(form: form)
     |> assign(brand_tab: :edit)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <div class="mb-8">
          <.button variant="ghost" size="sm" navigate={~p"/app/settings"}>
            &larr; {gettext("Back to Settings")}
          </.button>
          <h1 class="text-2xl font-bold text-zinc-900 dark:text-zinc-100 mt-2">
            {gettext("Branding")}
          </h1>
          <p class="mt-1 text-zinc-500 dark:text-zinc-400">
            {gettext("Customize your career page appearance")}
          </p>
        </div>

        <div class="mb-4 flex gap-1 rounded-lg bg-zinc-100 dark:bg-zinc-700 p-1 w-fit">
          <button
            type="button"
            phx-click="switch_brand_tab"
            phx-value-tab="edit"
            class={[
              "rounded-md px-4 py-1.5 text-sm font-medium",
              if(@brand_tab == :edit,
                do: "bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 shadow-sm",
                else: "text-zinc-500 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100"
              )
            ]}
          >
            {gettext("Edit")}
          </button>
          <button
            type="button"
            phx-click="switch_brand_tab"
            phx-value-tab="preview"
            class={[
              "rounded-md px-4 py-1.5 text-sm font-medium",
              if(@brand_tab == :preview,
                do: "bg-white dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 shadow-sm",
                else: "text-zinc-500 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100"
              )
            ]}
          >
            {gettext("Preview")}
          </button>
        </div>

        <div
          :if={@brand_tab == :edit}
          class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm p-6"
        >
          <.form
            for={@form}
            id="branding-form"
            phx-submit="save_branding"
            phx-change="validate_branding"
            class="space-y-4"
          >
            <.input
              field={@form[:title]}
              type="text"
              label={gettext("Page Title")}
              placeholder={gettext("Join our team")}
            />
            <.input
              field={@form[:description]}
              type="text"
              label={gettext("Subtitle")}
              placeholder={gettext("A short tagline under your company name")}
            />
            <.input
              field={@form[:about]}
              type="textarea"
              label={gettext("About")}
              placeholder={gettext("Tell candidates who you are and what you do...")}
              rows="10"
            />
            <p class="-mt-2 text-xs text-zinc-500 dark:text-zinc-400">
              {gettext("Supports Markdown formatting")}
            </p>

            <.button type="submit" variant="primary" class="w-full">
              {gettext("Save Branding")}
            </.button>
          </.form>
        </div>

        <div
          :if={@brand_tab == :preview}
          class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm p-6"
        >
          <div class="max-w-3xl mx-auto py-8 px-4">
            <div class="text-center mb-8">
              <h1 class="text-4xl font-bold text-zinc-900 dark:text-zinc-100">
                {@form[:title].value || @current_tenant.name}
              </h1>
              <p
                :if={@form[:description].value not in [nil, ""]}
                class="mt-4 text-lg text-zinc-500 dark:text-zinc-400"
              >
                {@form[:description].value}
              </p>
            </div>
            <.markdown
              :if={@form[:about].value not in [nil, ""]}
              text={@form[:about].value}
            />
            <p
              :if={@form[:about].value in [nil, ""]}
              class="text-center text-sm text-zinc-500 dark:text-zinc-400"
            >
              {gettext("Nothing to preview yet — write something in the About field.")}
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("validate_branding", %{"career_page" => page_params}, socket) do
    form = to_form(Careers.change_career_page(socket.assigns.career_page, page_params))
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("switch_brand_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, brand_tab: String.to_existing_atom(tab))}
  end

  def handle_event("save_branding", %{"career_page" => page_params}, socket) do
    result =
      case socket.assigns.career_page do
        %{id: nil} ->
          Careers.create_career_page(
            Map.put(page_params, "tenant_id", socket.assigns.current_tenant.id)
          )

        career_page ->
          Careers.update_career_page(career_page, page_params)
      end

    case result do
      {:ok, career_page} ->
        {:noreply,
         socket
         |> assign(career_page: career_page)
         |> assign(form: to_form(Careers.change_career_page(career_page)))
         |> put_flash(:info, gettext("Branding saved"))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(form: to_form(changeset))
         |> put_flash(:error, gettext("Please review the errors below"))}
    end
  end
end
