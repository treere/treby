defmodule TrebyWeb.SettingsLive.Fields do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Customization}
  alias Treby.Customization.CustomField

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

    custom_fields = Customization.list_custom_fields(tenant.id)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(custom_fields: custom_fields)
     |> assign(show_form: false)
     |> assign(editing_field: nil)
     |> assign(
       form: to_form(Customization.change_custom_field(%CustomField{tenant_id: tenant.id}))
     )
     |> assign(options_text: "")
     |> assign(new_option: "")
     |> assign(confirm_delete: nil)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <div class="flex justify-between items-center mb-8">
          <div>
            <.link navigate={~p"/app/settings"} class="text-blue-600 hover:text-blue-900 text-sm">
              &larr; Back to Settings
            </.link>
            <h1 class="text-2xl font-bold mt-2">{gettext("Custom Fields")}</h1>
            <p class="mt-1 text-base-content/70">
              {gettext("Define custom fields for candidates, jobs, and applications")}
            </p>
          </div>
          <button
            phx-click="show_create_form"
            class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
          >
            + Add Field
          </button>
        </div>

        <div :if={@show_form} class="mb-8 p-6 bg-base-100 rounded-lg shadow">
          <h2 class="text-lg font-semibold mb-4">
            {if @editing_field, do: gettext("Edit Field"), else: gettext("New Field")}
          </h2>
          <.form
            for={@form}
            id="field-form"
            phx-change="validate"
            phx-submit="save_field"
            class="space-y-4"
          >
            <div class="grid grid-cols-2 gap-4">
              <.input
                field={@form[:name]}
                type="text"
                label={gettext("Field Name")}
                placeholder="e.g. GitHub URL"
              />
              <.input
                field={@form[:field_type]}
                type="select"
                label={gettext("Type")}
                options={[
                  {"Text", "text"},
                  {"Number", "number"},
                  {"Date", "date"},
                  {gettext("Select (options)"), "select"},
                  {"URL", "url"}
                ]}
              />
              <.input
                field={@form[:applies_to]}
                type="select"
                label={gettext("Applies To")}
                options={[
                  {"Candidates", "candidate"},
                  {"Jobs", "job"},
                  {"Applications", "application"}
                ]}
              />
              <.input field={@form[:position]} type="number" label={gettext("Position")} />
            </div>

            <div :if={@form[:field_type].value == "select"} class="space-y-2">
              <label class="block text-sm font-medium text-base-content/80">
                {gettext("Options (one per line)")}
              </label>
              <textarea
                id="options-textarea"
                name="options_text"
                rows="3"
                class="textarea w-full"
              >{@options_text}</textarea>
            </div>

            <div class="flex items-center gap-2">
              <.input field={@form[:required]} type="checkbox" label={gettext("Required")} />
            </div>

            <div class="flex gap-2">
              <.button type="submit">{gettext("Save")}</.button>
              <.button type="button" phx-click="cancel_form" class="bg-gray-500">
                {gettext("Cancel")}
              </.button>
            </div>
          </.form>
        </div>

        <div class="bg-base-100 rounded-lg shadow overflow-hidden">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-base-200">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  {gettext("Name")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  {gettext("Type")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  {gettext("Applies To")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  {gettext("Required")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  {gettext("Actions")}
                </th>
              </tr>
            </thead>
            <tbody class="bg-base-100 divide-y divide-gray-200">
              <tr :for={field <- @custom_fields} class="hover:bg-base-200">
                <td class="px-6 py-4 whitespace-nowrap font-medium text-base-content">
                  {field.name}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-base-content/70">{field.field_type}</td>
                <td class="px-6 py-4 whitespace-nowrap text-base-content/70">{field.applies_to}</td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <%= if field.required do %>
                    <span class="text-green-600">{gettext("Yes")}</span>
                  <% else %>
                    <span class="text-base-content/40">No</span>
                  <% end %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <button
                    phx-click="edit_field"
                    phx-value-field_id={field.id}
                    class="text-blue-600 hover:text-blue-900 mr-3"
                  >
                    {gettext("Edit")}
                  </button>
                  <button
                    phx-click="confirm_delete"
                    phx-value-id={field.id}
                    phx-value-title={gettext("Delete field")}
                    phx-value-message={
                      gettext(
                        "Are you sure you want to delete this custom field? This action cannot be undone."
                      )
                    }
                    class="text-red-600 hover:text-red-900"
                  >
                    {gettext("Delete")}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
          <div :if={@custom_fields == []} class="p-8 text-center text-base-content/50">
            {gettext("No custom fields defined yet. Add your first custom field!")}
          </div>
        </div>
      </div>
    </Layouts.app>
    <.confirm_modal confirm_delete={@confirm_delete} on_confirm="do_delete_field" />
    """
  end

  def handle_event("show_create_form", _, socket) do
    form =
      to_form(
        Customization.change_custom_field(%CustomField{
          tenant_id: socket.assigns.current_tenant.id
        })
      )

    {:noreply, assign(socket, show_form: true, editing_field: nil, form: form, options_text: "")}
  end

  def handle_event("validate", params, socket) do
    form =
      %CustomField{tenant_id: socket.assigns.current_tenant.id}
      |> Customization.change_custom_field(Map.get(params, "custom_field", %{}))
      |> to_form()

    {:noreply,
     assign(socket,
       form: form,
       options_text: Map.get(params, "options_text", socket.assigns[:options_text] || "")
     )}
  end

  def handle_event("cancel_form", _, socket) do
    {:noreply, assign(socket, show_form: false, editing_field: nil)}
  end

  def handle_event("edit_field", %{"field_id" => field_id}, socket) do
    field = Customization.get_custom_field!(socket.assigns.current_tenant.id, field_id)
    form = to_form(Customization.change_custom_field(field))

    {:noreply,
     assign(socket,
       show_form: true,
       editing_field: field,
       form: form,
       options_text: Enum.join(field.options || [], "\n")
     )}
  end

  def handle_event("save_field", params, socket) do
    options_text = Map.get(params, "options_text", "")
    options = options_text |> String.split("\n", trim: true) |> Enum.map(&String.trim/1)

    field_params =
      params
      |> Map.get("custom_field", %{})
      |> Map.put("options", options)

    attrs = Map.put(field_params, "tenant_id", socket.assigns.current_tenant.id)

    result =
      case socket.assigns.editing_field do
        nil ->
          Customization.create_custom_field(attrs, socket.assigns.current_user)

        field ->
          Customization.update_custom_field(field, field_params, socket.assigns.current_user)
      end

    case result do
      {:ok, _field} ->
        custom_fields = Customization.list_custom_fields(socket.assigns.current_tenant.id)

        {:noreply,
         socket
         |> assign(
           custom_fields: custom_fields,
           show_form: false,
           editing_field: nil,
           options_text: ""
         )
         |> put_flash(:info, gettext("Field saved"))}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, gettext("Only admins can manage custom fields"))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(form: to_form(changeset))
         |> put_flash(:error, gettext("Please review the errors below"))}
    end
  end

  def handle_event(
        "confirm_delete",
        %{"id" => id, "title" => title, "message" => message},
        socket
      ) do
    {:noreply, assign(socket, confirm_delete: %{id: id, title: title, message: message})}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, confirm_delete: nil)}
  end

  def handle_event("do_delete_field", %{"id" => field_id}, socket) do
    field = Customization.get_custom_field!(socket.assigns.current_tenant.id, field_id)

    case Customization.delete_custom_field(field, socket.assigns.current_user) do
      {:ok, _} ->
        custom_fields = Customization.list_custom_fields(socket.assigns.current_tenant.id)

        {:noreply,
         socket
         |> assign(custom_fields: custom_fields, confirm_delete: nil)
         |> put_flash(:info, gettext("Field deleted"))}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> assign(confirm_delete: nil)
         |> put_flash(:error, gettext("Only admins can delete custom fields"))}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(confirm_delete: nil)
         |> put_flash(:error, gettext("Failed to delete field"))}
    end
  end
end
