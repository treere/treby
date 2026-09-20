defmodule TrebyWeb.SettingsLive.DataPrivacy do
  use TrebyWeb, :live_view

  alias Treby.DataPrivacy.Requests

  def mount(_params, _session, socket) do
    tenant = socket.assigns.current_tenant
    requests = if tenant, do: Requests.list_requests(tenant.id), else: []
    {:ok, assign(socket, requests: requests, settings_active: true)}
  end

  def handle_event("request_export", %{"scope" => scope}, socket) do
    tenant = socket.assigns.current_tenant
    user = socket.assigns.current_user

    if scope == "tenant" and socket.assigns.current_membership.role != "admin" do
      {:noreply, put_flash(socket, :error, gettext("Only admins can export tenant data"))}
    else
      attrs = %{
        tenant_id: tenant.id,
        requester_id: user.id,
        type: "export",
        scope: scope,
        status: "pending",
        metadata: %{}
      }

      case Requests.create_request(attrs) do
        {:ok, _} ->
          {:noreply,
           socket
           |> put_flash(:info, gettext("Export requested — processing"))
           |> assign(requests: Requests.list_requests(tenant.id))}

        {:error, changeset} ->
          {:noreply, put_flash(socket, :error, format_error(changeset))}
      end
    end
  end

  def handle_event("request_erasure", %{"scope" => scope, "confirm" => confirm}, socket) do
    tenant = socket.assigns.current_tenant
    user = socket.assigns.current_user

    cond do
      scope == "tenant" and socket.assigns.current_membership.role != "admin" ->
        {:noreply, put_flash(socket, :error, gettext("Only admins can erase company data"))}

      scope == "tenant" and confirm != tenant.slug ->
        {:noreply, put_flash(socket, :error, gettext("Confirmation does not match company slug"))}

      true ->
        grace_until =
          DateTime.add(DateTime.utc_now(), 7 * 24 * 60 * 60, :second) |> DateTime.to_iso8601()

        attrs = %{
          tenant_id: tenant.id,
          requester_id: user.id,
          type: "erasure",
          scope: scope,
          status: "pending",
          metadata: %{"grace_until" => grace_until}
        }

        if scope == "tenant" do
          settings = Map.put(tenant.settings || %{}, "data_privacy_pending_erasure", grace_until)
          tenant |> Ecto.Changeset.change(%{settings: settings}) |> Treby.Repo.update()
        end

        case Requests.create_request(attrs) do
          {:ok, _} ->
            {:noreply,
             socket
             |> put_flash(:info, gettext("Erasure requested — 7 day grace period"))
             |> assign(requests: Requests.list_requests(tenant.id))}

          {:error, changeset} ->
            {:noreply, put_flash(socket, :error, format_error(changeset))}
        end
    end
  end

  def handle_event("request_erasure", %{"scope" => scope}, socket) do
    handle_event("request_erasure", %{"scope" => scope, "confirm" => ""}, socket)
  end

  def handle_event("cancel", %{"id" => id}, socket) do
    tenant = socket.assigns.current_tenant

    case Requests.get_request(tenant.id, id) do
      nil ->
        {:noreply, put_flash(socket, :error, gettext("Not found"))}

      request ->
        case Requests.cancel(request) do
          {:ok, _} ->
            {:noreply,
             socket
             |> put_flash(:info, gettext("Request cancelled"))
             |> assign(requests: Requests.list_requests(tenant.id))}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, gettext("Cannot cancel"))}
        end
    end
  end

  def handle_event("filter", %{"type" => type, "status" => status}, socket) do
    tenant = socket.assigns.current_tenant
    opts = []
    opts = if type != "", do: Keyword.put(opts, :type, type), else: opts
    opts = if status != "", do: Keyword.put(opts, :status, status), else: opts
    {:noreply, assign(socket, requests: Requests.list_requests(tenant.id, opts))}
  end

  defp format_error(%Ecto.Changeset{} = cs) do
    cs |> Ecto.Changeset.traverse_errors(fn {msg, _} -> msg end) |> inspect()
  end

  defp format_error(other), do: inspect(other)

  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_user}
      locale={@locale}
      current_tenant={assigns[:current_tenant]}
      notification_unread_count={assigns[:notification_unread_count] || 0}
      notification_recent={assigns[:notification_recent] || []}
    >
      <div class="p-8">
        <TrebyWeb.SettingsLayout.settings_shell
          current_tenant={@current_tenant}
          current_membership={@current_membership}
          active_key={:data_privacy}
        >
          <.page_header
            title={gettext("Data & Privacy")}
            subtitle={gettext("Data export and erasure requests")}
          />

          <div class="mt-6 flex gap-4">
            <form phx-submit="request_export" class="flex gap-2">
              <input type="hidden" name="scope" value="user" />
              <.button type="submit" variant="secondary" id="data-privacy-export-user">
                {gettext("Export my data")}
              </.button>
            </form>
            <form
              :if={@current_membership.role == "admin"}
              phx-submit="request_export"
              class="flex gap-2"
            >
              <input type="hidden" name="scope" value="tenant" />
              <.button type="submit" variant="primary" id="data-privacy-export-tenant">
                {gettext("Export company data")}
              </.button>
            </form>
          </div>

          <div class="mt-6 border-t pt-6">
            <h3 class="font-semibold">{gettext("Request erasure")}</h3>
            <p class="text-sm text-zinc-500">{gettext("7-day grace period — you can cancel")}</p>
            <div class="mt-4 flex gap-4 items-end">
              <form phx-submit="request_erasure" class="flex gap-2 items-end">
                <input type="hidden" name="scope" value="user" />
                <.button type="submit" variant="danger" id="data-privacy-erasure-user">
                  {gettext("Delete my account")}
                </.button>
              </form>
              <form
                :if={@current_membership.role == "admin"}
                phx-submit="request_erasure"
                class="flex gap-2 items-end"
              >
                <input type="hidden" name="scope" value="tenant" />
                <input
                  type="text"
                  name="confirm"
                  placeholder={@current_tenant && @current_tenant.slug}
                  class="border rounded-xl px-3 py-2"
                  id="data-privacy-erasure-confirm"
                />
                <.button type="submit" variant="danger" id="data-privacy-erasure-tenant">
                  {gettext("Delete company")}
                </.button>
              </form>
            </div>
          </div>

          <div class="mt-8">
            <form phx-change="filter" id="data-privacy-filter" class="flex gap-2 mb-4">
              <select name="type" class="border rounded-xl px-2 py-1">
                <option value="">{gettext("All types")}</option>
                <option value="export">{gettext("Export")}</option>
                <option value="erasure">{gettext("Erasure")}</option>
              </select>
              <select name="status" class="border rounded-xl px-2 py-1">
                <option value="">{gettext("All status")}</option>
                <option value="pending">pending</option>
                <option value="processing">processing</option>
                <option value="ready">ready</option>
                <option value="completed">completed</option>
                <option value="expired">expired</option>
                <option value="cancelled">cancelled</option>
                <option value="failed">failed</option>
              </select>
            </form>

            <div id="data-privacy-requests" class="space-y-2">
              <div
                :for={req <- @requests}
                id={"req-#{req.id}"}
                class="border rounded-xl p-4 flex justify-between items-center"
              >
                <div>
                  <span class="font-mono text-sm">{req.type} / {req.scope}</span>
                  <span class="ml-2 text-sm px-2 py-1 rounded bg-zinc-100 dark:bg-zinc-700">{req.status}</span>
                </div>
                <div class="flex gap-2">
                  <.button
                    :if={req.status == "ready" and req.s3_key}
                    variant="secondary"
                    size="sm"
                    navigate={~p"/#{@current_tenant.slug}/data-privacy/exports/#{req.id}/download"}
                    id={"data-privacy-download-#{req.id}"}
                  >
                    {gettext("Download")}
                  </.button>
                  <.button
                    :if={req.status in ["pending", "processing"]}
                    variant="ghost"
                    size="sm"
                    phx-click="cancel"
                    phx-value-id={req.id}
                    id={"data-privacy-cancel-#{req.id}"}
                  >
                    {gettext("Cancel")}
                  </.button>
                </div>
              </div>
              <div :if={@requests == []} class="text-sm text-zinc-500">
                {gettext("No requests yet")}
              </div>
            </div>
          </div>
        </TrebyWeb.SettingsLayout.settings_shell>
      </div>
    </Layouts.app>
    """
  end
end
