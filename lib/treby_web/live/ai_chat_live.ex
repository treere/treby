defmodule TrebyWeb.AiChatLive do
  use TrebyWeb, :live_view

  alias Treby.AI.{Agent, Conversations, Tools}

  @impl true
  def mount(_params, session, socket) do
    user = socket.assigns.current_user
    tenant = socket.assigns.current_tenant

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Treby.PubSub, Conversations.topic(tenant.id, user.id))
    end

    conversation =
      Conversations.resolve_conversation(tenant.id, user.id, session["ai_conversation_id"])

    socket =
      socket
      |> assign(:page_title, "Assistant")
      |> assign(:ai_conversation_id, session["ai_conversation_id"])
      |> assign(:current_path, "/#{tenant.slug}/app/ai")
      |> assign(:current_params, %{})
      |> assign(:pending_runs, Conversations.list_pending_tool_runs(conversation))
      |> stream(:messages, Conversations.list_messages(conversation))

    {:ok, socket}
  end

  @impl true
  def handle_event("send_message", %{"message" => text}, socket) do
    user = socket.assigns.current_user

    case Treby.RateLimit.check(:ai_message, user.id) do
      :allow ->
        case Agent.chat(socket, text) do
          {:ok, _status} ->
            {:noreply, reload(socket)}

          {:error, :empty} ->
            {:noreply, socket}

          {:error, reason} ->
            {:noreply, put_flash(socket, :error, error_message(reason))}
        end

      {:deny, _retry_after} ->
        {:noreply,
         put_flash(socket, :error, gettext("Too many messages. Please wait a moment and retry."))}
    end
  end

  def handle_event("confirm_tool_run", %{"id" => id}, socket) do
    tenant = socket.assigns.current_tenant
    user = socket.assigns.current_user

    socket =
      case Conversations.get_tool_run(tenant.id, id) do
        nil ->
          socket

        run ->
          case Agent.confirm_tool_run(run, %{tenant_id: tenant.id, user: user}) do
            {:ok, _result} -> put_flash(socket, :info, gettext("Action completed."))
            {:error, _reason} -> put_flash(socket, :error, gettext("Action failed."))
          end
      end

    {:noreply, reload(socket)}
  end

  def handle_event("reject_tool_run", %{"id" => id}, socket) do
    tenant = socket.assigns.current_tenant

    socket =
      case Conversations.get_tool_run(tenant.id, id) do
        nil ->
          socket

        run ->
          {:ok, _} = Agent.reject_tool_run(run)
          put_flash(socket, :info, gettext("Action cancelled."))
      end

    {:noreply, reload(socket)}
  end

  def handle_event("reset_conversation", _params, socket) do
    tenant = socket.assigns.current_tenant
    user = socket.assigns.current_user
    conversation = Conversations.reset_conversation(tenant.id, user.id)

    {:noreply,
     socket
     |> assign(:ai_conversation_id, conversation.id)
     |> reload()}
  end

  @impl true
  def handle_info({:ai_updated, user_id}, socket) do
    if user_id == socket.assigns.current_user.id do
      {:noreply, reload(socket)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp reload(socket) do
    tenant = socket.assigns.current_tenant
    user = socket.assigns.current_user

    conversation =
      Conversations.resolve_conversation(tenant.id, user.id, socket.assigns[:ai_conversation_id])

    socket
    |> assign(:pending_runs, Conversations.list_pending_tool_runs(conversation))
    |> stream(:messages, Conversations.list_messages(conversation), reset: true)
  end

  defp tool_label(tool) do
    case Tools.get(tool) do
      nil -> tool
      module -> module.name()
    end
  end

  defp error_message(reason) do
    case reason do
      :too_many_iterations ->
        gettext("The assistant took too many steps. Please try again.")

      message when is_binary(message) ->
        gettext("The assistant is unavailable: %{message}", message: message)

      _ ->
        gettext("The assistant is currently unavailable. Please try again.")
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_user}
      current_tenant={@current_tenant}
      locale={@locale}
      available_tenants={assigns[:available_tenants] || []}
    >
      <div class="p-4 sm:p-8 max-w-3xl mx-auto">
        <div class="flex items-center justify-between mb-6">
          <div>
            <h1 class="text-2xl font-bold text-zinc-900 dark:text-zinc-100">
              {gettext("Assistant")}
            </h1>
            <p class="text-sm text-zinc-500 dark:text-zinc-400">
              {gettext("Ask about jobs, the platform, or the page you are on.")}
            </p>
          </div>
          <div class="relative">
            <button
              type="button"
              phx-click={Phoenix.LiveView.JS.toggle(to: "#reset-confirm")}
              class="inline-flex items-center gap-2 px-3 py-1.5 text-sm font-medium rounded-lg border border-zinc-200 dark:border-zinc-700 text-zinc-700 dark:text-zinc-300 hover:bg-zinc-50 dark:hover:bg-zinc-800 transition-colors"
            >
              {gettext("Reset")}
            </button>
            <div
              id="reset-confirm"
              class="hidden absolute right-0 mt-2 w-64 p-4 bg-white dark:bg-zinc-800 rounded-xl shadow-xl border border-zinc-200 dark:border-zinc-700 z-40"
            >
              <p class="text-sm text-zinc-700 dark:text-zinc-300 mb-3">
                {gettext("Start a new conversation? The current one is kept but no longer shown.")}
              </p>
              <div class="flex justify-end gap-2">
                <button
                  type="button"
                  phx-click={Phoenix.LiveView.JS.hide(to: "#reset-confirm")}
                  class="px-3 py-1.5 text-sm font-medium rounded-lg text-zinc-600 dark:text-zinc-300 hover:bg-zinc-100 dark:hover:bg-zinc-700"
                >
                  {gettext("Cancel")}
                </button>
                <button
                  type="button"
                  id="reset-confirm-button"
                  phx-click="reset_conversation"
                  class="px-3 py-1.5 text-sm font-medium rounded-lg bg-orange-600 text-white hover:bg-orange-700 transition-colors"
                >
                  {gettext("Reset")}
                </button>
              </div>
            </div>
          </div>
        </div>

        <div
          id="ai-messages"
          phx-update="stream"
          class="space-y-4 min-h-[12rem]"
        >
          <div
            :for={{dom_id, message} <- @streams.messages}
            id={dom_id}
            class={["flex", message.role == "user" && "justify-end"]}
          >
            <div class={[
              "max-w-[85%] rounded-xl px-4 py-3 text-sm",
              message.role == "user" &&
                "bg-zinc-900 text-white dark:bg-white dark:text-zinc-900",
              message.role != "user" &&
                "bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-800 dark:text-zinc-100 md-content"
            ]}>
              <%= if message.role == "user" do %>
                <p class="whitespace-pre-wrap">{message.content}</p>
              <% else %>
                {TrebyWeb.Markdown.to_safe_html(message.content)}
              <% end %>
            </div>
          </div>
        </div>

        <div :if={@pending_runs != []} class="mt-6 space-y-3">
          <div
            :for={run <- @pending_runs}
            id={"tool-run-" <> run.id}
            class="rounded-xl border border-amber-300 dark:border-amber-700 bg-amber-50 dark:bg-amber-900/20 p-4"
          >
            <p class="text-sm font-semibold text-amber-800 dark:text-amber-200">
              {gettext("Confirmation required: %{tool}", tool: tool_label(run.tool))}
            </p>
            <pre class="mt-2 text-xs text-amber-900 dark:text-amber-100 overflow-x-auto">{Jason.encode!(run.args, pretty: true)}</pre>
            <div class="mt-3 flex gap-2">
              <button
                type="button"
                id={"confirm-" <> run.id}
                phx-click="confirm_tool_run"
                phx-value-id={run.id}
                class="px-3 py-1.5 text-sm font-medium rounded-lg bg-orange-600 text-white hover:bg-orange-700 transition-colors"
              >
                {gettext("Confirm")}
              </button>
              <button
                type="button"
                id={"reject-" <> run.id}
                phx-click="reject_tool_run"
                phx-value-id={run.id}
                class="px-3 py-1.5 text-sm font-medium rounded-lg border border-zinc-300 dark:border-zinc-600 text-zinc-700 dark:text-zinc-300 hover:bg-zinc-100 dark:hover:bg-zinc-700 transition-colors"
              >
                {gettext("Cancel")}
              </button>
            </div>
          </div>
        </div>

        <form id="ai-form" phx-submit="send_message" class="mt-6 flex gap-2">
          <input
            id="ai-input"
            type="text"
            name="message"
            autocomplete="off"
            required
            placeholder={gettext("Ask the assistant...")}
            class="flex-1 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-4 py-3 text-sm text-zinc-900 dark:text-zinc-100 focus:outline-none focus:ring-2 focus:ring-orange-500"
          />
          <button
            type="submit"
            id="ai-send"
            class="px-4 py-3 text-sm font-medium rounded-xl bg-orange-600 text-white hover:bg-orange-700 transition-colors"
          >
            {gettext("Send")}
          </button>
        </form>
      </div>
    </Layouts.app>
    """
  end
end
