defmodule TrebyWeb.SettingsLive.CompanyAvailability do
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

    if user.role != "admin" do
      {:noreply,
       push_navigate(socket,
         to:
           if(socket.assigns.current_tenant,
             do: "/#{socket.assigns.current_tenant.slug}/app/settings/availability",
             else: ~p"/app/settings/availability"
           )
       )}
    else
      rules = Availability.list_company_rules(tenant.id)

      {:ok,
       socket
       |> assign(settings_active: true)
       |> assign(current_user: user, current_tenant: tenant)
       |> assign(rules: rules)
       |> assign(company_timezone: tenant.timezone)
       |> assign(show_form: false)
       |> assign(editing_rule: nil)
       |> assign(
         form:
           to_form(
             Availability.change_rule(%AvailabilityRule{tenant_id: tenant.id, scope: "company"})
           )
       )
       |> assign(days_of_week: @days_of_week)
       |> assign(timezones: @timezones)
       |> assign(confirm_delete: nil)}
    end
  end

  defp day_name(0), do: gettext("Sunday")
  defp day_name(1), do: gettext("Monday")
  defp day_name(2), do: gettext("Tuesday")
  defp day_name(3), do: gettext("Wednesday")
  defp day_name(4), do: gettext("Thursday")
  defp day_name(5), do: gettext("Friday")
  defp day_name(6), do: gettext("Saturday")

  defp format_time(time) do
    Calendar.strftime(time, "%H:%M")
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <TrebyWeb.SettingsLayout.settings_shell
          current_tenant={@current_tenant}
          current_membership={@current_membership}
          active_key={:company_availability}
        >
          <div class="mb-8">
            <.button
              variant="ghost"
              size="sm"
              navigate={
                if @current_tenant,
                  do: "/#{@current_tenant.slug}/app/settings",
                  else: ~p"/app/settings"
              }
            >
              &larr; {gettext("Back to Settings")}
            </.button>
            <h1 class="text-2xl font-bold text-zinc-900 dark:text-zinc-100 mt-2">
              {gettext("Company Availability")}
            </h1>
            <p class="mt-1 text-zinc-500 dark:text-zinc-400">
              {gettext(
                "Set the company's default available hours. New team members start with a copy of this schedule."
              )}
            </p>
            <div class="mt-4 flex items-center gap-3">
              <label
                for="company-timezone"
                class="text-sm font-medium text-zinc-900 dark:text-zinc-100"
              >
                {gettext("Company Timezone")}
              </label>
              <select
                name="timezone"
                id="company-timezone"
                phx-change="update_timezone"
                class="rounded-lg border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-3 py-2 text-sm text-zinc-900 dark:text-zinc-100 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-orange-500"
              >
                <option :for={tz <- @timezones} value={tz} selected={tz == @company_timezone}>
                  {tz}
                </option>
              </select>
            </div>
          </div>

          <div class="mb-6">
            <.button variant="primary" phx-click="show_create_form">
              <.icon name="hero-plus" class="mr-2 h-4 w-4" /> Add Time Slot
            </.button>
          </div>

          <div
            :if={@show_form}
            class="mb-8 bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm p-6"
          >
            <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100 mb-4">
              {if @editing_rule, do: gettext("Edit Time Slot"), else: "New Time Slot"}
            </h2>
            <.form
              for={@form}
              id="company-availability-form"
              phx-submit="save_rule"
              phx-change="validate_rule"
              class="space-y-4"
            >
              <.input
                field={@form[:day_of_week]}
                type="select"
                label={gettext("Day of Week")}
                options={Enum.map(@days_of_week, fn {val, label} -> {label, val} end)}
              />
              <div class="grid grid-cols-2 gap-4">
                <.input field={@form[:start_time]} type="time" label={gettext("Start Time")} />
                <.input field={@form[:end_time]} type="time" label={gettext("End Time")} />
              </div>
              <div class="flex gap-4">
                <.button type="submit" loading_text={gettext("Saving...")}>{gettext("Save")}</.button>
                <.button type="button" variant="ghost" phx-click="cancel_form">
                  Cancel
                </.button>
              </div>
            </.form>
          </div>

          <div class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm overflow-x-auto">
            <table class="min-w-full divide-y divide-zinc-100 dark:divide-zinc-700">
              <thead class="bg-zinc-50 dark:bg-zinc-800">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase">
                    Day
                  </th>
                  <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase">
                    Hours
                  </th>
                  <th class="px-6 py-3 text-right text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody class="bg-white dark:bg-zinc-800 divide-y divide-zinc-100 dark:divide-zinc-700">
                <%= for rule <- @rules do %>
                  <tr>
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-zinc-900 dark:text-zinc-100">
                      {day_name(rule.day_of_week)}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-zinc-500 dark:text-zinc-400">
                      {format_time(rule.start_time)} - {format_time(rule.end_time)}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <button
                        phx-click="edit_rule"
                        phx-value-rule_id={rule.id}
                        class="text-blue-600 dark:text-blue-400 hover:text-blue-900 dark:hover:text-blue-300 mr-4"
                      >
                        Edit
                      </button>
                      <button
                        phx-click="confirm_delete"
                        phx-value-id={rule.id}
                        phx-value-title={gettext("Delete rule")}
                        phx-value-message={
                          gettext(
                            "Are you sure you want to delete this availability rule? This action cannot be undone."
                          )
                        }
                        class="text-red-600 dark:text-red-400 hover:text-red-900 dark:hover:text-red-300"
                      >
                        {gettext("Delete")}
                      </button>
                    </td>
                  </tr>
                <% end %>
                <tr :if={@rules == []}>
                  <td
                    colspan="3"
                    class="px-6 py-8 text-center text-sm text-zinc-500 dark:text-zinc-400"
                  >
                    No company availability set. Add default time slots to enable interview scheduling.
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </TrebyWeb.SettingsLayout.settings_shell>
      </div>

      <.confirm_dialog
        id="confirm-company-availability"
        show={@confirm_delete != nil}
        title={@confirm_delete && @confirm_delete.title}
        message={@confirm_delete && @confirm_delete.message}
        confirm_label="Delete"
        confirm_variant="danger"
        on_confirm="do_delete_rule"
        on_cancel="cancel_delete"
        extra_attrs={(@confirm_delete && %{id: @confirm_delete.id}) || %{}}
      />
    </Layouts.app>
    """
  end

  def handle_event("show_create_form", _, socket) do
    form =
      to_form(
        Availability.change_rule(%AvailabilityRule{
          tenant_id: socket.assigns.current_tenant.id,
          scope: "company"
        })
      )

    {:noreply, assign(socket, show_form: true, editing_rule: nil, form: form)}
  end

  def handle_event("update_timezone", %{"timezone" => timezone}, socket) do
    tenant = socket.assigns.current_tenant
    {:ok, _tenant} = Tenants.update_tenant(tenant, %{timezone: timezone})

    {:noreply,
     assign(socket, current_tenant: %{tenant | timezone: timezone}, company_timezone: timezone)}
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
          %AvailabilityRule{tenant_id: socket.assigns.current_tenant.id, scope: "company"}

        r ->
          r
      end

    form = to_form(Availability.change_rule(rule, rule_params))
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save_rule", %{"availability_rule" => rule_params}, socket) do
    attrs =
      rule_params
      |> Map.put("tenant_id", socket.assigns.current_tenant.id)
      |> Map.put("scope", "company")
      |> Map.delete("user_id")

    result =
      case socket.assigns.editing_rule do
        nil -> Availability.create_rule(attrs)
        rule -> Availability.update_rule(rule, rule_params)
      end

    case result do
      {:ok, _rule} ->
        rules = Availability.list_company_rules(socket.assigns.current_tenant.id)
        {:noreply, assign(socket, rules: rules, show_form: false, editing_rule: nil)}

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

  def handle_event("cancel_delete", _, socket) do
    {:noreply, assign(socket, confirm_delete: nil)}
  end

  def handle_event("do_delete_rule", %{"id" => id}, socket) do
    rule = Availability.get_rule!(id)
    {:ok, _} = Availability.delete_rule(rule)
    rules = Availability.list_company_rules(socket.assigns.current_tenant.id)
    {:noreply, assign(socket, rules: rules, confirm_delete: nil)}
  end
end
