defmodule TrebyWeb.SettingsLive.Sources do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Sources}
  alias Treby.Sources.Source

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])

    sources = Sources.list_sources(tenant.id)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(sources: sources)
     |> assign(show_form: false)
     |> assign(editing_id: nil)
     |> assign(form: to_form(Source.changeset(%Source{}, %{})))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <h1 class="text-2xl font-bold">{gettext("Sources")}</h1>
        <p class="mt-2 text-gray-600">{gettext("Manage how candidates find you")}</p>

        <div class="mt-6">
          <button
            :if={not @show_form}
            phx-click="show_create_form"
            class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            {gettext("Add Source")}
          </button>
        </div>

        <.form
          :if={@show_form}
          for={@form}
          id="source-form"
          phx-submit="save_source"
          phx-change="validate_source"
          class="mt-6 bg-white rounded-lg shadow p-6"
        >
          <.input field={@form[:name]} type="text" label={gettext("Source Name")} />
          <div class="mt-4 flex gap-2">
            <.button type="submit">{gettext("Save")}</.button>
            <.button type="button" phx-click="cancel_form" class="bg-gray-500">
              {gettext("Cancel")}
            </.button>
          </div>
        </.form>

        <div class="mt-8 space-y-4">
          <div
            :for={source <- @sources}
            class="bg-white rounded-lg shadow p-4 flex items-center justify-between"
          >
            <div>
              <span class="font-medium text-gray-900">{source.name}</span>
              <span
                :if={source.is_default}
                class="ml-2 text-xs bg-gray-100 text-gray-600 px-2 py-1 rounded"
              >
                {gettext("Default")}
              </span>
            </div>
            <div class="flex gap-2">
              <button
                :if={@editing_id != source.id}
                phx-click="edit_source"
                phx-value-id={source.id}
                class="text-blue-600 hover:text-blue-800"
              >
                {gettext("Edit")}
              </button>
              <.form
                :if={@editing_id == source.id}
                for={@form}
                id={"edit-source-#{source.id}"}
                phx-submit="update_source"
                phx-value-id={source.id}
                class="flex gap-2 items-center"
              >
                <.input field={@form[:name]} type="text" />
                <.button type="submit">{gettext("Save")}</.button>
                <.button type="button" phx-click="cancel_edit" class="bg-gray-500">
                  {gettext("Cancel")}
                </.button>
              </.form>
              <button
                :if={not source.is_default}
                phx-click="delete_source"
                phx-value-id={source.id}
                data-confirm={gettext("Delete this source? Applications will be re-tagged as Other.")}
                class="text-red-600 hover:text-red-800"
              >
                {gettext("Delete")}
              </button>
            </div>
          </div>

          <div :if={@sources == []} class="text-center py-8 text-gray-500">
            {gettext("No sources configured yet")}
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("show_create_form", _, socket) do
    {:noreply,
     socket
     |> assign(show_form: true)
     |> assign(form: to_form(Source.changeset(%Source{}, %{})))}
  end

  def handle_event("cancel_form", _, socket) do
    {:noreply,
     socket
     |> assign(show_form: false)
     |> assign(form: to_form(Source.changeset(%Source{}, %{})))}
  end

  def handle_event("validate_source", %{"source" => params}, socket) do
    changeset =
      %Source{}
      |> Source.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save_source", %{"source" => params}, socket) do
    attrs = Map.put(params, "tenant_id", socket.assigns.current_tenant.id)

    case Sources.create_source(attrs) do
      {:ok, _source} ->
        sources = Sources.list_sources(socket.assigns.current_tenant.id)

        {:noreply,
         socket
         |> assign(sources: sources, show_form: false)
         |> assign(form: to_form(Source.changeset(%Source{}, %{})))
         |> put_flash(:info, gettext("Source added"))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("edit_source", %{"id" => id}, socket) do
    source = Sources.get_source!(socket.assigns.current_tenant.id, id)

    {:noreply,
     socket
     |> assign(editing_id: id)
     |> assign(form: to_form(Source.changeset(source, %{})))}
  end

  def handle_event("cancel_edit", _, socket) do
    {:noreply,
     socket
     |> assign(editing_id: nil)
     |> assign(form: to_form(Source.changeset(%Source{}, %{})))}
  end

  def handle_event("update_source", %{"id" => id, "source" => params}, socket) do
    source = Sources.get_source!(socket.assigns.current_tenant.id, id)

    case Sources.update_source(source, params) do
      {:ok, _source} ->
        sources = Sources.list_sources(socket.assigns.current_tenant.id)

        {:noreply,
         socket
         |> assign(sources: sources, editing_id: nil)
         |> assign(form: to_form(Source.changeset(%Source{}, %{})))
         |> put_flash(:info, gettext("Source updated"))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("delete_source", %{"id" => id}, socket) do
    source = Sources.get_source!(socket.assigns.current_tenant.id, id)

    case Sources.delete_source(source) do
      {:ok, _} ->
        sources = Sources.list_sources(socket.assigns.current_tenant.id)

        {:noreply,
         socket
         |> assign(sources: sources)
         |> put_flash(:info, gettext("Source deleted"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to delete source"))}
    end
  end
end
