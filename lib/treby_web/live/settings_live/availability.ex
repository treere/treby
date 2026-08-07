defmodule TrebyWeb.SettingsLive.Availability do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Availability}
  alias Treby.Availability.AvailabilityRule

  @days_of_week [
    {0, "Sunday"},
    {1, "Monday"},
    {2, "Tuesday"},
    {3, "Wednesday"},
    {4, "Thursday"},
    {5, "Friday"},
    {6, "Saturday"}
  ]

  @timezones [
    "UTC",
    "America/New_York",
    "America/Chicago",
    "America/Denver",
    "America/Los_Angeles",
    "Europe/London",
    "Europe/Paris",
    "Europe/Berlin",
    "Europe/Rome",
    "Asia/Tokyo",
    "Asia/Shanghai",
    "Australia/Sydney"
  ]

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])
    rules = Availability.list_rules_for_user(user.id)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(rules: rules)
     |> assign(show_form: false)
     |> assign(editing_rule: nil)
     |> assign(
       form:
         to_form(
           Availability.change_rule(%AvailabilityRule{user_id: user.id, tenant_id: tenant.id})
         )
     )
     |> assign(days_of_week: @days_of_week)
     |> assign(timezones: @timezones)
     |> assign(confirm_delete: nil)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <div class="mb-8">
          <.link navigate={~p"/app/settings"} class="text-blue-600 hover:text-blue-900 text-sm">
            &larr; Back to Settings
          </.link>
          <h1 class="text-2xl font-bold mt-2">Availability</h1>
          <p class="mt-1 text-base-content/70">Set your available hours for interview scheduling</p>
        </div>

        <div class="mb-6">
          <button
            phx-click="show_create_form"
            class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
          >
            <.icon name="hero-plus" class="mr-2 h-4 w-4" /> Add Availability
          </button>
        </div>

        <div :if={@show_form} class="mb-8 bg-base-100 rounded-lg shadow p-6">
          <h2 class="text-lg font-semibold mb-4">
            {if @editing_rule, do: "Edit Availability", else: "New Availability"}
          </h2>
          <.form
            for={@form}
            id="availability-form"
            phx-submit="save_rule"
            phx-change="validate_rule"
            class="space-y-4"
          >
            <.input
              field={@form[:day_of_week]}
              type="select"
              label="Day of Week"
              options={Enum.map(@days_of_week, fn {val, label} -> {label, val} end)}
            />
            <div class="grid grid-cols-2 gap-4">
              <.input field={@form[:start_time]} type="time" label="Start Time" />
              <.input field={@form[:end_time]} type="time" label="End Time" />
            </div>
            <.input
              field={@form[:timezone]}
              type="select"
              label="Timezone"
              options={@timezones}
            />
            <div class="grid grid-cols-2 gap-4">
              <.input
                field={@form[:buffer_before]}
                type="number"
                label="Buffer Before (minutes)"
                min="0"
              />
              <.input
                field={@form[:buffer_after]}
                type="number"
                label="Buffer After (minutes)"
                min="0"
              />
            </div>
            <div class="flex gap-4">
              <.button type="submit">Save</.button>
              <.button type="button" phx-click="cancel_form" class="bg-gray-500 hover:bg-gray-600">
                Cancel
              </.button>
            </div>
          </.form>
        </div>

        <div class="bg-base-100 rounded-lg shadow overflow-hidden">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-base-200">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase">
                  Day
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase">
                  Hours
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase">
                  Timezone
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase">
                  Buffer
                </th>
                <th class="px-6 py-3 text-right text-xs font-medium text-base-content/50 uppercase">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-base-100 divide-y divide-gray-200">
              <%= for rule <- @rules do %>
                <tr>
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-base-content">
                    {day_name(rule.day_of_week)}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-base-content/50">
                    {format_time(rule.start_time)} - {format_time(rule.end_time)}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-base-content/50">
                    {rule.timezone}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-base-content/50">
                    {rule.buffer_before}min before / {rule.buffer_after}min after
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <button
                      phx-click="edit_rule"
                      phx-value-rule_id={rule.id}
                      class="text-blue-600 hover:text-blue-900 mr-4"
                    >
                      Edit
                    </button>
                    <button
                      phx-click="confirm_delete"
                      phx-value-id={rule.id}
                      phx-value-title="Delete rule"
                      phx-value-message="Are you sure you want to delete this availability rule? This action cannot be undone."
                      class="text-red-600 hover:text-red-900"
                    >
                      Delete
                    </button>
                  </td>
                </tr>
              <% end %>
              <tr :if={@rules == []}>
                <td colspan="5" class="px-6 py-8 text-center text-sm text-base-content/50">
                  No availability rules set. Add your available hours to enable interview scheduling.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </Layouts.app>
    <.confirm_modal confirm_delete={@confirm_delete} on_confirm="do_delete_rule" />
    """
  end

  def handle_event("show_create_form", _, socket) do
    form =
      to_form(
        Availability.change_rule(%AvailabilityRule{
          user_id: socket.assigns.current_user.id,
          tenant_id: socket.assigns.current_tenant.id,
          timezone: "UTC",
          buffer_before: 15,
          buffer_after: 15
        })
      )

    {:noreply, assign(socket, show_form: true, editing_rule: nil, form: form)}
  end

  def handle_event("edit_rule", %{"rule_id" => rule_id}, socket) do
    rule = Availability.get_rule!(rule_id)
    form = to_form(Availability.change_rule(rule))

    {:noreply, assign(socket, show_form: true, editing_rule: rule, form: form)}
  end

  def handle_event("cancel_form", _, socket) do
    {:noreply, assign(socket, show_form: false, editing_rule: nil)}
  end

  def handle_event("validate_rule", %{"availability_rule" => rule_params}, socket) do
    rule =
      case socket.assigns.editing_rule do
        nil ->
          %AvailabilityRule{
            user_id: socket.assigns.current_user.id,
            tenant_id: socket.assigns.current_tenant.id
          }

        r ->
          r
      end

    form = to_form(Availability.change_rule(rule, rule_params))
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save_rule", %{"availability_rule" => rule_params}, socket) do
    attrs =
      rule_params
      |> Map.put("user_id", socket.assigns.current_user.id)
      |> Map.put("tenant_id", socket.assigns.current_tenant.id)

    result =
      case socket.assigns.editing_rule do
        nil -> Availability.create_rule(attrs)
        rule -> Availability.update_rule(rule, rule_params)
      end

    case result do
      {:ok, _} ->
        rules = Availability.list_rules_for_user(socket.assigns.current_user.id)

        {:noreply,
         socket
         |> assign(rules: rules, show_form: false, editing_rule: nil)
         |> put_flash(:info, "Availability saved")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(form: to_form(changeset))
         |> put_flash(:error, "Please review the errors below")}
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

  def handle_event("do_delete_rule", %{"id" => rule_id}, socket) do
    rule = Availability.get_rule!(rule_id)
    {:ok, _} = Availability.delete_rule(rule)

    rules = Availability.list_rules_for_user(socket.assigns.current_user.id)

    {:noreply,
     socket
     |> assign(rules: rules, confirm_delete: nil)
     |> put_flash(:info, "Availability rule deleted")}
  end

  defp day_name(day), do: @days_of_week |> Enum.find(fn {d, _} -> d == day end) |> elem(1)

  defp format_time(time) do
    case time do
      %Time{} -> Elixir.Calendar.strftime(time, "%H:%M")
      {:ok, time} -> Elixir.Calendar.strftime(time, "%H:%M")
      time when is_binary(time) -> String.slice(time, 0, 5)
      _ -> ""
    end
  end
end
