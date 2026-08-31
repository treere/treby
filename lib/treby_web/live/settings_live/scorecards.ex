defmodule TrebyWeb.SettingsLive.Scorecards do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Scorecards}

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

    templates = Scorecards.list_scorecard_templates(tenant.id)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(templates: templates)
     |> assign(show_form: false)
     |> assign(editing_template: nil)
     |> assign(form_name: "")
     |> assign(criteria: [])
     |> assign(confirm_delete: nil)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <div class="flex justify-between items-center mb-8">
          <div>
            <.link navigate={~p"/app/settings"} class="text-blue-600 hover:text-blue-900 text-sm">
              &larr; {gettext("Back to Settings")}
            </.link>
            <h1 class="text-2xl font-bold mt-2">{gettext("Scorecard Templates")}</h1>
            <p class="mt-1 text-base-content/70">
              {gettext("Define evaluation criteria for interviews")}
            </p>
          </div>
          <.button phx-click="show_create_form" variant="primary">
            + {gettext("Add Template")}
          </.button>
        </div>

        <div :if={@show_form} class="mb-8 p-6 bg-base-100 rounded-lg shadow">
          <h2 class="text-lg font-semibold mb-4">
            {if @editing_template, do: gettext("Edit Template"), else: gettext("New Template")}
          </h2>
          <form
            id="template-form"
            phx-submit="save_template"
            phx-change="form_changed"
            class="space-y-4"
          >
            <div>
              <label class="block text-sm font-medium text-base-content/80">
                {gettext("Template Name")}
              </label>
              <input
                type="text"
                name="name"
                value={@form_name}
                placeholder={gettext("e.g. Engineering Interview")}
                class="input w-full"
              />
            </div>

            <div class="space-y-2">
              <label class="block text-sm font-medium text-base-content/80">
                {gettext("Criteria")}
              </label>
              <div
                :for={{criterion, idx} <- Enum.with_index(@criteria)}
                class="flex gap-2 items-center"
              >
                <span class="text-sm text-base-content/50 w-8">{idx + 1}.</span>
                <input
                  type="text"
                  name={"criteria[#{idx}][name]"}
                  value={criterion["name"]}
                  class="input flex-1"
                  placeholder={gettext("Criterion name")}
                />
                <select
                  name={"criteria[#{idx}][type]"}
                  class="select"
                >
                  <option value="number_1_5" selected={criterion["type"] == "number_1_5"}>
                    {gettext("Number (1-5)")}
                  </option>
                  <option value="yes_no_maybe" selected={criterion["type"] == "yes_no_maybe"}>
                    {gettext("Yes/No/Maybe")}
                  </option>
                  <option value="text" selected={criterion["type"] == "text"}>
                    {gettext("Text")}
                  </option>
                </select>
                <button
                  type="button"
                  phx-click="remove_criterion"
                  phx-value-index={idx}
                  class="text-red-600 hover:text-red-900"
                >
                  <.icon name="hero-x-mark" class="w-5 h-5" />
                </button>
              </div>

              <div
                id="criterion-adder"
                phx-hook=".CriterionAdder"
                class="flex gap-2 items-center mt-2"
              >
                <input
                  type="text"
                  id="new_criterion_name"
                  placeholder={gettext("New criterion name")}
                  class="input flex-1"
                />
                <select
                  id="new_criterion_type"
                  class="select"
                >
                  <option value="number_1_5">{gettext("Number (1-5)")}</option>
                  <option value="yes_no_maybe">{gettext("Yes/No/Maybe")}</option>
                  <option value="text">{gettext("Text")}</option>
                </select>
                <.button
                  type="button"
                  id="add-criterion-btn"
                  variant="primary"
                  size="sm"
                >
                  + {gettext("Add")}
                </.button>
              </div>
              <script :type={Phoenix.LiveView.ColocatedHook} name=".CriterionAdder">
                export default {
                  mounted() {
                    document.getElementById("add-criterion-btn").addEventListener("click", () => {
                      const name = document.getElementById("new_criterion_name").value;
                      const type = document.getElementById("new_criterion_type").value;
                      if (name.trim()) {
                        this.pushEvent("add_criterion", { new_criterion_name: name, new_criterion_type: type });
                      }
                    });
                  }
                }
              </script>
            </div>

            <div class="flex gap-2">
              <.button type="submit" variant="primary">{gettext("Save")}</.button>
              <.button type="button" phx-click="cancel_form" variant="ghost">
                {gettext("Cancel")}
              </.button>
            </div>
          </form>
        </div>

        <div class="bg-base-100 rounded-lg shadow overflow-hidden">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-base-200">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  {gettext("Name")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  {gettext("Criteria Count")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  {gettext("Actions")}
                </th>
              </tr>
            </thead>
            <tbody class="bg-base-100 divide-y divide-gray-200">
              <tr :for={template <- @templates} class="hover:bg-base-200">
                <td class="px-6 py-4 whitespace-nowrap font-medium text-base-content">
                  {template.name}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-base-content/70">
                  {length(template.criteria || [])}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <button
                    phx-click="edit_template"
                    phx-value-template_id={template.id}
                    class="text-blue-600 hover:text-blue-900 mr-3"
                  >
                    {gettext("Edit")}
                  </button>
                  <button
                    phx-click="confirm_delete"
                    phx-value-id={template.id}
                    phx-value-title={gettext("Delete template")}
                    phx-value-message={
                      gettext(
                        "Are you sure you want to delete this scorecard template? This action cannot be undone."
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
          <div :if={@templates == []} class="p-8 text-center text-base-content/50">
            {gettext("No scorecard templates yet. Create your first template!")}
          </div>
        </div>
      </div>
    </Layouts.app>
    <.confirm_dialog
      id="confirm-scorecard"
      show={@confirm_delete != nil}
      title={@confirm_delete && @confirm_delete.title}
      message={@confirm_delete && @confirm_delete.message}
      confirm_label="Delete"
      confirm_variant="danger"
      on_confirm="do_delete_template"
      on_cancel="cancel_delete"
      extra_attrs={(@confirm_delete && %{id: @confirm_delete.id}) || %{}}
    />
    """
  end

  def handle_event("show_create_form", _, socket) do
    {:noreply,
     assign(socket, show_form: true, editing_template: nil, form_name: "", criteria: [])}
  end

  def handle_event("cancel_form", _, socket) do
    {:noreply, assign(socket, show_form: false, editing_template: nil)}
  end

  def handle_event("form_changed", %{"name" => name}, socket) do
    {:noreply, assign(socket, form_name: name)}
  end

  def handle_event("form_changed", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("edit_template", %{"template_id" => template_id}, socket) do
    template = Scorecards.get_scorecard_template!(template_id)

    {:noreply,
     assign(socket,
       show_form: true,
       editing_template: template,
       form_name: template.name,
       criteria: template.criteria || []
     )}
  end

  def handle_event("add_criterion", params, socket) do
    name = Map.get(params, "new_criterion_name", "")
    type = Map.get(params, "new_criterion_type", "number_1_5")

    if name != "" do
      new_criteria =
        socket.assigns.criteria ++
          [%{"name" => name, "type" => type, "position" => length(socket.assigns.criteria)}]

      {:noreply, assign(socket, criteria: new_criteria)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("remove_criterion", %{"index" => index}, socket) do
    idx = String.to_integer(index)

    new_criteria =
      socket.assigns.criteria
      |> Enum.with_index()
      |> Enum.reject(fn {_, i} -> i == idx end)
      |> Enum.map(fn {c, _} -> c end)

    {:noreply, assign(socket, criteria: new_criteria)}
  end

  def handle_event("save_template", params, socket) do
    criteria_text = Map.get(params, "criteria", %{})

    criteria =
      criteria_text
      |> Map.values()
      |> Enum.with_index()
      |> Enum.map(fn {c, idx} ->
        %{
          "name" => Map.get(c, "name", ""),
          "type" => Map.get(c, "type", "number_1_5"),
          "position" => idx
        }
      end)
      |> Enum.filter(fn c -> c["name"] != "" end)

    template_params = %{
      "name" => Map.get(params, "name", ""),
      "criteria" => criteria,
      "tenant_id" => socket.assigns.current_tenant.id
    }

    result =
      case socket.assigns.editing_template do
        nil ->
          Scorecards.create_scorecard_template(template_params, socket.assigns.current_user)

        template ->
          Scorecards.update_scorecard_template(
            template,
            template_params,
            socket.assigns.current_user
          )
      end

    case result do
      {:ok, _template} ->
        templates = Scorecards.list_scorecard_templates(socket.assigns.current_tenant.id)

        {:noreply,
         socket
         |> assign(templates: templates, show_form: false, editing_template: nil)
         |> put_flash(:info, gettext("Template saved"))}

      {:error, :unauthorized} ->
        {:noreply,
         put_flash(socket, :error, gettext("Only admins can manage scorecard templates"))}

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

  def handle_event("do_delete_template", %{"id" => template_id}, socket) do
    template = Scorecards.get_scorecard_template!(template_id)

    case Scorecards.delete_scorecard_template(template, socket.assigns.current_user) do
      {:ok, _} ->
        templates = Scorecards.list_scorecard_templates(socket.assigns.current_tenant.id)

        {:noreply,
         socket
         |> assign(templates: templates, confirm_delete: nil)
         |> put_flash(:info, gettext("Template deleted"))}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> assign(confirm_delete: nil)
         |> put_flash(:error, gettext("Only admins can delete scorecard templates"))}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(confirm_delete: nil)
         |> put_flash(:error, gettext("Failed to delete template"))}
    end
  end
end
