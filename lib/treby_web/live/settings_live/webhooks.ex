defmodule TrebyWeb.SettingsLive.Webhooks do
  use TrebyWeb, :live_view

  alias Treby.Webhooks
  alias Treby.Webhooks.WebhookSubscription

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)

    {user, tenant, membership} =
      case session do
        %{"user_id" => user_id, "tenant_id" => tenant_id} ->
          user = Treby.Accounts.get_user!(user_id)
          tenant = Treby.Tenants.get_tenant!(tenant_id)
          membership = Treby.Memberships.get_membership(user.id, tenant.id)
          {user, tenant, membership}

        _ ->
          {nil, nil, nil}
      end

    if is_nil(tenant) do
      {:ok, redirect(socket, to: "/choose-tenant")}
    else
      {:ok,
       socket
       |> assign(current_user: user, current_tenant: tenant, current_membership: membership)
       |> assign(
         show_modal: false,
         editing_id: nil,
         secret_reveal: nil,
         test_result: nil,
         confirm_delete: nil,
         expanded_logs: nil,
         logs: [],
         form: nil
       )
       |> load_subscriptions()}
    end
  end

  defp load_subscriptions(socket) do
    subs = Webhooks.list_subscriptions(socket.assigns.current_tenant.id)
    assign(socket, subscriptions: subs)
  end

  defp new_form(socket) do
    changeset = Webhooks.create_subscription(socket.assigns.current_tenant.id, %{})
    to_form(changeset, as: :webhook_subscription)
  end

  defp edit_form(_socket, subscription) do
    attrs = %{events_text: Enum.join(subscription.events, ", ")}
    changeset = Webhooks.update_subscription(subscription, attrs)
    to_form(changeset, as: :webhook_subscription)
  end

  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_user}
      locale={@locale}
      current_tenant={@current_tenant}
      current_membership={@current_membership}
      available_tenants={assigns[:available_tenants] || []}
    >
      <div class="p-8">
        <div class="flex justify-between items-center mb-8">
          <div>
            <.button variant="ghost" size="sm" navigate={~p"/app/settings"}>
              &larr; {gettext("Back to Settings")}
            </.button>
            <h1 class="text-2xl font-bold text-zinc-900 dark:text-zinc-100 mt-2">
              {gettext("Webhooks")}
            </h1>
            <p class="mt-1 text-zinc-500 dark:text-zinc-400">
              {gettext("Send Treby events to external systems via signed outbound webhooks.")}
            </p>
          </div>
          <.button variant="primary" phx-click="new">{gettext("New Webhook")}</.button>
        </div>

        <div
          :if={@secret_reveal}
          class="mb-6 p-4 bg-zinc-50 dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700"
        >
          <p class="text-sm font-medium text-zinc-900 dark:text-zinc-100">
            {gettext("Secret (shown once — save it now)")}
          </p>
          <code class="block mt-2 text-xs break-all text-zinc-700 dark:text-zinc-300">{@secret_reveal}</code>
        </div>

        <div class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm overflow-hidden">
          <div class="px-6 py-4 border-b">
            <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
              {gettext("Subscriptions")}
            </h2>
          </div>

          <div
            :if={Enum.empty?(@subscriptions)}
            class="px-6 py-10 text-center text-zinc-500 dark:text-zinc-400"
          >
            {gettext("No webhooks configured yet.")}
          </div>

          <table
            :if={not Enum.empty?(@subscriptions)}
            class="min-w-full divide-y divide-zinc-100 dark:divide-zinc-700"
          >
            <thead class="bg-zinc-50 dark:bg-zinc-800">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider">
                  {gettext("Target URL")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider">
                  {gettext("Events")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider">
                  {gettext("Status")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider">
                  {gettext("Actions")}
                </th>
              </tr>
            </thead>
            <tbody class="bg-white dark:bg-zinc-800 divide-y divide-zinc-100 dark:divide-zinc-700">
              <tr :for={sub <- @subscriptions} class="hover:bg-zinc-50 dark:hover:bg-zinc-700/50">
                <td class="px-6 py-4">
                  <div class="font-medium text-zinc-900 dark:text-zinc-100 break-all">
                    {sub.target_url}
                  </div>
                  <div :if={sub.description != ""} class="text-xs text-zinc-500 dark:text-zinc-400">
                    {sub.description}
                  </div>
                </td>
                <td class="px-6 py-4">
                  <span
                    :for={ev <- sub.events}
                    class="inline-block px-2 py-0.5 mr-1 mb-1 text-xs rounded-full bg-zinc-100 dark:bg-zinc-700 text-zinc-700 dark:text-zinc-200"
                  >{ev}</span>
                </td>
                <td class="px-6 py-4">
                  <.badge variant={if sub.active, do: "success", else: "default"}>
                    {if sub.active, do: gettext("Active"), else: gettext("Paused")}
                  </.badge>
                </td>
                <td class="px-6 py-4 text-sm whitespace-nowrap">
                  <button
                    phx-click="toggle_active"
                    phx-value-id={sub.id}
                    class="text-zinc-600 dark:text-zinc-300 hover:text-zinc-900 dark:hover:text-zinc-100 mr-3"
                  >
                    {if sub.active, do: gettext("Pause"), else: gettext("Resume")}
                  </button>
                  <button
                    phx-click="test_saved"
                    phx-value-id={sub.id}
                    class="text-zinc-600 dark:text-zinc-300 hover:text-zinc-900 dark:hover:text-zinc-100 mr-3"
                  >
                    {gettext("Send test")}
                  </button>
                  <button
                    phx-click="edit"
                    phx-value-id={sub.id}
                    class="text-zinc-600 dark:text-zinc-300 hover:text-zinc-900 dark:hover:text-zinc-100 mr-3"
                  >
                    {gettext("Edit")}
                  </button>
                  <button
                    phx-click="confirm_delete"
                    phx-value-id={sub.id}
                    phx-value-title={gettext("Delete webhook")}
                    phx-value-message={gettext("Are you sure? This cannot be undone.")}
                    class="text-red-600 dark:text-red-400 hover:text-red-900 dark:hover:text-red-300"
                  >
                    {gettext("Delete")}
                  </button>
                  <button
                    phx-click="toggle_logs"
                    phx-value-id={sub.id}
                    class="text-zinc-600 dark:text-zinc-300 hover:text-zinc-900 dark:hover:text-zinc-100 ml-3"
                  >
                    {gettext("Logs")}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>

          <div :if={@expanded_logs} class="px-6 py-4 bg-zinc-50 dark:bg-zinc-900/50 border-t">
            <h3 class="text-sm font-semibold text-zinc-900 dark:text-zinc-100 mb-2">
              {gettext("Recent deliveries")}
            </h3>
            <div :if={Enum.empty?(@logs)} class="text-sm text-zinc-500 dark:text-zinc-400">
              {gettext("No deliveries yet.")}
            </div>
            <table
              :if={not Enum.empty?(@logs)}
              class="min-w-full text-sm divide-y divide-zinc-100 dark:divide-zinc-700"
            >
              <tbody>
                <tr :for={log <- @logs} class="divide-x divide-zinc-100 dark:divide-zinc-700">
                  <td class="px-2 py-1">
                    <.badge variant={if log.status == "success", do: "success", else: "danger"}>
                      {log.status}
                    </.badge>
                  </td>
                  <td class="px-2 py-1 text-zinc-600 dark:text-zinc-300">{log.action}</td>
                  <td class="px-2 py-1 text-zinc-500 dark:text-zinc-400">{log.last_response}</td>
                  <td class="px-2 py-1 text-zinc-400">
                    {Calendar.strftime(log.inserted_at, "%Y-%m-%d %H:%M")}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <.modal
        id="webhook-modal"
        show={@show_modal}
        title={if @editing_id, do: gettext("Edit Webhook"), else: gettext("New Webhook")}
      >
        <.form
          :if={@form}
          for={@form}
          id="webhook-form"
          phx-submit="save"
          phx-change="validate"
          class="space-y-4"
        >
          <.input
            field={@form[:target_url]}
            type="url"
            label={gettext("Target URL")}
            placeholder="https://example.com/webhook"
          />
          <.input
            field={@form[:events_text]}
            type="text"
            label={gettext("Events")}
            placeholder="candidate.*, job.created, *"
          />
          <p class="text-xs text-zinc-500 dark:text-zinc-400 -mt-2">
            {gettext(
              "Comma-separated. Use exact events (candidate.created), namespace wildcards (candidate.*) or * for all."
            )}
          </p>
          <.input field={@form[:description]} type="text" label={gettext("Description (optional)")} />
          <.input
            field={@form[:secret]}
            type="text"
            label={gettext("Secret (optional — auto-generated if blank)")}
          />
          <label class="flex items-center gap-2 text-sm text-zinc-700 dark:text-zinc-200">
            <.input field={@form[:active]} type="checkbox" />
            {gettext("Active")}
          </label>

          <div
            :if={@test_result}
            class={"text-sm " <> if String.starts_with?(@test_result, "OK"), do: "text-green-600 dark:text-green-400", else: "text-red-600 dark:text-red-400"}
          >
            {gettext("Test: ")}<span class="font-medium">{@test_result}</span>
          </div>

          <div class="flex gap-2 pt-2">
            <.button type="submit" variant="primary">{gettext("Save")}</.button>
            <.button type="button" phx-click="test_modal">{gettext("Send test")}</.button>
            <.button type="button" variant="ghost" phx-click="cancel">{gettext("Cancel")}</.button>
          </div>
        </.form>
      </.modal>

      <.confirm_dialog
        id="webhook-confirm"
        show={@confirm_delete != nil}
        title={@confirm_delete && @confirm_delete.title}
        message={@confirm_delete && @confirm_delete.message}
        confirm_label={gettext("Delete")}
        confirm_variant="danger"
        on_confirm="do_delete"
        on_cancel="cancel_delete"
        extra_attrs={(@confirm_delete && %{id: @confirm_delete.id}) || %{}}
      />
    </Layouts.app>
    """
  end

  def handle_event("new", _, socket) do
    {:noreply,
     assign(socket,
       show_modal: true,
       editing_id: nil,
       secret_reveal: nil,
       test_result: nil,
       form: new_form(socket)
     )}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    case Webhooks.get_subscription(socket.assigns.current_tenant.id, id) do
      nil ->
        {:noreply, socket}

      sub ->
        {:noreply,
         assign(socket,
           show_modal: true,
           editing_id: id,
           secret_reveal: nil,
           test_result: nil,
           form: edit_form(socket, sub)
         )}
    end
  end

  def handle_event("cancel", _, socket) do
    {:noreply, assign(socket, show_modal: false, editing_id: nil, form: nil)}
  end

  def handle_event("validate", %{"webhook_subscription" => params}, socket) do
    changeset = build_changeset(socket, params)
    {:noreply, assign(socket, form: to_form(changeset, as: :webhook_subscription))}
  end

  def handle_event("save", %{"webhook_subscription" => params}, socket) do
    tenant = socket.assigns.current_tenant
    changeset = build_changeset(socket, params)

    case changeset do
      %{valid?: false} ->
        {:noreply, assign(socket, form: to_form(changeset, as: :webhook_subscription))}

      _ ->
        result =
          if socket.assigns.editing_id do
            sub = Webhooks.get_subscription(tenant.id, socket.assigns.editing_id)

            Webhooks.update_subscription(sub, extract_attrs(params))
            |> Webhooks.save_subscription()
          else
            Webhooks.create_subscription(tenant.id, extract_attrs(params))
            |> Webhooks.save_subscription()
          end

        case result do
          {:ok, saved} ->
            {:noreply,
             socket
             |> assign(show_modal: false, editing_id: nil, form: nil)
             |> assign(secret_reveal: if(socket.assigns.editing_id, do: nil, else: saved.secret))
             |> load_subscriptions()}

          {:error, c} ->
            {:noreply, assign(socket, form: to_form(c, as: :webhook_subscription))}
        end
    end
  end

  def handle_event("toggle_active", %{"id" => id}, socket) do
    tenant = socket.assigns.current_tenant

    case Webhooks.get_subscription(tenant.id, id) do
      nil ->
        {:noreply, socket}

      sub ->
        Webhooks.update_subscription(sub, %{active: not sub.active})
        |> Webhooks.save_subscription()
    end

    {:noreply, load_subscriptions(socket)}
  end

  def handle_event("toggle_logs", %{"id" => id}, socket) do
    if socket.assigns.expanded_logs == id do
      {:noreply, assign(socket, expanded_logs: nil, logs: [])}
    else
      logs = Webhooks.list_delivery_logs(id)
      {:noreply, assign(socket, expanded_logs: id, logs: logs)}
    end
  end

  def handle_event("test_modal", %{"webhook_subscription" => params}, socket) do
    url = Map.get(params, "target_url", "")
    secret = Map.get(params, "secret", "")
    secret = if secret == "", do: Base.url_encode64(:crypto.strong_rand_bytes(24)), else: secret
    result = Webhooks.test_ping(url, secret)
    {:noreply, assign(socket, test_result: format_test(result))}
  end

  def handle_event("test_saved", %{"id" => id}, socket) do
    tenant = socket.assigns.current_tenant

    result =
      case Webhooks.get_subscription(tenant.id, id) do
        nil -> {:error, "not found"}
        sub -> Webhooks.test_ping(sub.target_url, sub.secret)
      end

    {:noreply,
     put_flash(
       socket,
       if(match?({:ok, _}, result), do: :info, else: :error),
       gettext("Test: ") <> format_test(result)
     )}
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

  def handle_event("do_delete", %{"id" => id}, socket) do
    tenant = socket.assigns.current_tenant

    case Webhooks.get_subscription(tenant.id, id) do
      nil -> :ok
      sub -> Webhooks.delete_subscription(sub)
    end

    {:noreply, assign(socket, confirm_delete: nil) |> load_subscriptions()}
  end

  defp build_changeset(socket, params) do
    attrs = extract_attrs(params)

    if socket.assigns.editing_id do
      sub = Webhooks.get_subscription(socket.assigns.current_tenant.id, socket.assigns.editing_id)

      Webhooks.update_subscription(
        sub || %WebhookSubscription{tenant_id: socket.assigns.current_tenant.id},
        attrs
      )
    else
      Webhooks.create_subscription(socket.assigns.current_tenant.id, attrs)
    end
  end

  defp extract_attrs(params) do
    %{
      "target_url" => Map.get(params, "target_url", ""),
      "events_text" => Map.get(params, "events_text", ""),
      "description" => Map.get(params, "description", ""),
      "secret" => Map.get(params, "secret", ""),
      "active" => param_to_bool(Map.get(params, "active"))
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp param_to_bool(nil), do: true
  defp param_to_bool("true"), do: true
  defp param_to_bool("false"), do: false
  defp param_to_bool("on"), do: true
  defp param_to_bool(v) when is_boolean(v), do: v
  defp param_to_bool(_), do: true

  defp format_test({:ok, status}), do: "OK (HTTP #{status})"
  defp format_test({:error, reason}), do: to_string(reason)
end
