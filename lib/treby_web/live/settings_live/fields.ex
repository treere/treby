defmodule TrebyWeb.SettingsLive.Fields do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Customization}
  alias Treby.Customization.CustomField

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])
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
            <h1 class="text-2xl font-bold mt-2">Custom Fields</h1>
            <p class="mt-1 text-gray-600">
              Define custom fields for candidates, jobs, and applications
            </p>
          </div>
          <button
            phx-click="show_create_form"
            class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
          >
            + Add Field
          </button>
        </div>

        <div :if={@show_form} class="mb-8 p-6 bg-white rounded-lg shadow">
          <h2 class="text-lg font-semibold mb-4">
            {if @editing_field, do: "Edit Field", else: "New Field"}
          </h2>
          <.form
            for={@form}
            id="field-form"
            phx-submit="save_field"
            class="space-y-4"
          >
            <div class="grid grid-cols-2 gap-4">
              <.input
                field={@form[:name]}
                type="text"
                label="Field Name"
                placeholder="e.g. GitHub URL"
              />
              <.input
                field={@form[:field_type]}
                type="select"
                label="Type"
                options={[
                  {"Text", "text"},
                  {"Number", "number"},
                  {"Date", "date"},
                  {"Select (options)", "select"},
                  {"URL", "url"}
                ]}
              />
              <.input
                field={@form[:applies_to]}
                type="select"
                label="Applies To"
                options={[
                  {"Candidates", "candidate"},
                  {"Jobs", "job"},
                  {"Applications", "application"}
                ]}
              />
              <.input field={@form[:position]} type="number" label="Position" />
            </div>

            <div :if={@form[:field_type].value == "select"} class="space-y-2">
              <label class="block text-sm font-medium text-gray-700">Options (one per line)</label>
              <textarea
                id="options-textarea"
                name="options_text"
                rows="3"
                class="block w-full rounded-lg border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
              ><%= Enum.join(@form[:options].value || [], "\n") %></textarea>
            </div>

            <div class="flex items-center gap-2">
              <.input field={@form[:required]} type="checkbox" label="Required" />
            </div>

            <div class="flex gap-2">
              <.button type="submit">Save</.button>
              <.button type="button" phx-click="cancel_form" class="bg-gray-500">Cancel</.button>
            </div>
          </.form>
        </div>

        <div class="bg-white rounded-lg shadow overflow-hidden">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Name
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Type
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Applies To
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Required
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr :for={field <- @custom_fields} class="hover:bg-gray-50">
                <td class="px-6 py-4 whitespace-nowrap font-medium text-gray-900">{field.name}</td>
                <td class="px-6 py-4 whitespace-nowrap text-gray-600">{field.field_type}</td>
                <td class="px-6 py-4 whitespace-nowrap text-gray-600">{field.applies_to}</td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <%= if field.required do %>
                    <span class="text-green-600">Yes</span>
                  <% else %>
                    <span class="text-gray-400">No</span>
                  <% end %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <button
                    phx-click="edit_field"
                    phx-value-field_id={field.id}
                    class="text-blue-600 hover:text-blue-900 mr-3"
                  >
                    Edit
                  </button>
                  <button
                    phx-click="confirm_delete"
                    phx-value-id={field.id}
                    phx-value-title="Delete field"
                    phx-value-message="Are you sure you want to delete this custom field? This action cannot be undone."
                    class="text-red-600 hover:text-red-900"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
          <div :if={@custom_fields == []} class="p-8 text-center text-gray-500">
            No custom fields defined yet. Add your first custom field!
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

    {:noreply, assign(socket, show_form: true, editing_field: nil, form: form)}
  end

  def handle_event("cancel_form", _, socket) do
    {:noreply, assign(socket, show_form: false, editing_field: nil)}
  end

  def handle_event("edit_field", %{"field_id" => field_id}, socket) do
    field = Customization.get_custom_field!(socket.assigns.current_tenant.id, field_id)
    form = to_form(Customization.change_custom_field(field))
    {:noreply, assign(socket, show_form: true, editing_field: field, form: form)}
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
         |> assign(custom_fields: custom_fields, show_form: false, editing_field: nil)
         |> put_flash(:info, "Field saved")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "Only admins can manage custom fields")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
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
         |> put_flash(:info, "Field deleted")}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> assign(confirm_delete: nil)
         |> put_flash(:error, "Only admins can delete custom fields")}

      {:error, _} ->
        {:noreply,
         socket |> assign(confirm_delete: nil) |> put_flash(:error, "Failed to delete field")}
    end
  end
end
