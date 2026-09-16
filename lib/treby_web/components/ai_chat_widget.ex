defmodule TrebyWeb.AiChatWidget do
  @moduledoc """
  Floating assistant chat widget, rendered inside the app layout on every
  authenticated page and full-width on the dedicated assistant page.

  State lives in the component; messages live in the DB. The parent LiveView
  relays AI PubSub messages here via `send_update/2`.
  """

  use TrebyWeb, :live_component

  alias Treby.AI.{Agent, Conversations, Context, Session, Tools}

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:streaming, false)
     |> assign(:streaming_text, "")
     |> assign(:thinking, false)
     |> assign(:open, false)
     |> assign(:message, "")
     |> assign(:ai_error, nil)
     |> assign(:pending_runs, [])
     |> assign(:ai_loaded, false)}
  end

  @impl true
  def update(%{stream_chunk: chunk}, socket) do
    {:ok,
     socket
     |> assign(:streaming, true)
     |> assign(:streaming_text, (socket.assigns[:streaming_text] || "") <> chunk)}
  end

  def update(%{ai_reload: true}, socket) do
    {:ok, reload(socket)}
  end

  def update(%{ai_error: reason}, socket) do
    {:ok,
     socket
     |> assign(:ai_error, error_message(reason))
     |> assign(:streaming, false)
     |> assign(:thinking, false)}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket = if socket.assigns[:ai_loaded], do: socket, else: reload(socket)
    {:ok, assign(socket, :ai_loaded, true)}
  end

  @impl true
  def handle_event("set_open", %{"open" => open}, socket) do
    {:noreply, assign(socket, :open, open in [true, "true", "1"])}
  end

  @impl true
  def handle_event("send_message", %{"message" => text}, socket) do
    if socket.assigns[:thinking] do
      {:noreply, socket}
    else
      text = String.trim(text || "")
      ctx = session_ctx(socket)
      user_id = ctx.current_user.id

      cond do
        text == "" ->
          {:noreply, assign(socket, :message, "")}

        match?({:deny, _}, Treby.RateLimit.check(:ai_message, user_id)) ->
          {:noreply,
           assign(socket,
             message: "",
             ai_error: gettext("Too many messages. Please wait a moment and retry.")
           )}

        true ->
          ctx = build_ctx(socket)

          {:ok, _pid} =
            Task.Supervisor.start_child(Treby.TaskSupervisor, fn -> Session.chat(ctx, text) end)

          {:noreply, assign(socket, message: "", ai_error: nil, thinking: true)}
      end
    end
  end

  def handle_event("confirm_tool_run", %{"id" => id}, socket) do
    ctx = session_ctx(socket)
    tenant = ctx.current_tenant
    user = ctx.current_user

    case Conversations.get_tool_run(tenant.id, id) do
      nil ->
        {:noreply, socket}

      run ->
        case Agent.confirm_tool_run(run, %{tenant_id: tenant.id, user: user}) do
          {:ok, _result} -> {:noreply, reload(assign(socket, :ai_error, nil))}
          {:error, _reason} -> {:noreply, assign(socket, :ai_error, gettext("Action failed."))}
        end
    end
  end

  def handle_event("reject_tool_run", %{"id" => id}, socket) do
    tenant = session_ctx(socket).current_tenant

    case Conversations.get_tool_run(tenant.id, id) do
      nil ->
        {:noreply, socket}

      run ->
        {:ok, _} = Agent.reject_tool_run(run)
        {:noreply, reload(assign(socket, :ai_error, nil))}
    end
  end

  def handle_event("reset_conversation", _params, socket) do
    ctx = session_ctx(socket)

    Conversations.reset_conversation(
      ctx.current_tenant.id,
      ctx.current_user.id,
      ctx.ai_session_token
    )

    {:noreply, reload(assign(socket, :ai_error, nil))}
  end

  defp reload(socket) do
    host = host(socket)
    tenant = socket.assigns[:current_tenant] || host[:current_tenant]
    user = socket.assigns[:current_user] || host[:current_user]
    token = socket.assigns[:ai_session_token] || host[:ai_session_token]

    conversation =
      if tenant && user, do: Conversations.resolve_conversation(tenant.id, user.id, token)

    messages = if conversation, do: Conversations.list_messages(conversation), else: []
    last_msg = List.last(messages)

    thinking =
      socket.assigns[:thinking] && last_msg != nil && last_msg.role == "user"

    socket
    |> assign(:pending_runs, Conversations.list_pending_tool_runs(conversation))
    |> assign(:streaming, false)
    |> assign(:streaming_text, "")
    |> assign(:thinking, thinking)
    |> stream(:messages, messages, reset: true)
  end

  defp build_ctx(socket) do
    host = host(socket)
    current = socket.assigns

    assigns =
      Map.merge(host, %{
        current_user: current[:current_user] || host[:current_user],
        current_tenant: current[:current_tenant] || host[:current_tenant],
        current_membership: current[:current_membership] || host[:current_membership],
        current_path: current[:current_path] || host[:current_path],
        current_params: current[:current_params] || host[:current_params] || %{},
        current_view: current[:current_view] || host[:current_view],
        ai_session_token: current[:ai_session_token] || host[:ai_session_token]
      })

    ctx = Context.build(%{assigns: assigns, view: assigns[:current_view]})
    Map.put(ctx, :host_pid, socket.root_pid)
  end

  defp host(socket) do
    Process.get(:ai_host_assigns) || socket.assigns[:host_assigns] || %{}
  end

  defp session_ctx(socket) do
    host = host(socket)

    %{
      current_user: socket.assigns[:current_user] || host[:current_user],
      current_tenant: socket.assigns[:current_tenant] || host[:current_tenant],
      ai_session_token: socket.assigns[:ai_session_token] || host[:ai_session_token]
    }
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
    <div
      id={@id}
      phx-hook={@variant == :floating && "AiChatToggle"}
      class={@variant == :page && "p-4 sm:p-8 max-w-3xl mx-auto"}
    >
      <%= if @variant == :page do %>
        <.chat_panel
          id="ai-chat"
          myself={@myself}
          variant={@variant}
          streaming={@streaming}
          streaming_text={@streaming_text}
          thinking={@thinking}
          message={@message}
          ai_error={@ai_error}
          pending_runs={@pending_runs}
          streams={@streams}
        />
      <% else %>
        <button
          type="button"
          data-ai-chat-toggle
          id="ai-chat-trigger"
          aria-label={gettext("Toggle assistant")}
          class="fixed bottom-4 right-4 z-40 flex items-center gap-2 rounded-full bg-orange-600 px-4 py-3 text-sm font-medium text-white shadow-lg hover:bg-orange-700 transition-colors"
        >
          <.icon name="hero-sparkles" class="w-5 h-5" />
        </button>

        <div
          data-ai-chat-panel
          id="ai-chat-panel"
          class={[
            "fixed bottom-4 right-4 z-40 flex flex-col w-[24rem] max-w-[calc(100vw-2rem)] h-[32rem] max-h-[calc(100vh-2rem)] rounded-2xl border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-900 shadow-2xl overflow-hidden",
            !@open && "hidden"
          ]}
        >
          <.chat_panel
            id="ai-chat-floating"
            myself={@myself}
            variant={@variant}
            streaming={@streaming}
            streaming_text={@streaming_text}
            thinking={@thinking}
            message={@message}
            ai_error={@ai_error}
            pending_runs={@pending_runs}
            streams={@streams}
          />
        </div>
      <% end %>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :myself, :any, required: true
  attr :variant, :atom, default: :floating
  attr :current_user, :map, default: nil
  attr :current_tenant, :map, default: nil
  attr :streaming, :boolean, default: false
  attr :streaming_text, :string, default: ""
  attr :thinking, :boolean, default: false
  attr :message, :string, default: ""
  attr :ai_error, :string, default: nil
  attr :pending_runs, :list, default: []
  attr :streams, :map, default: %{}

  defp chat_panel(assigns) do
    ~H"""
    <div class="flex flex-col h-full min-h-0">
      <div class="flex items-center justify-between px-4 py-3 border-b border-zinc-200 dark:border-zinc-700">
        <div>
          <h2 class="text-base font-semibold text-zinc-900 dark:text-zinc-100">
            {gettext("Assistant")}
          </h2>
          <p class="text-xs text-zinc-500 dark:text-zinc-400">
            {gettext("Ask about jobs, the platform, or the page you are on.")}
          </p>
        </div>
        <div class="flex items-center gap-1">
          <button
            type="button"
            id={"ai-reset-" <> @id}
            phx-target={@myself}
            phx-click="reset_conversation"
            class="px-2.5 py-1.5 text-xs font-medium rounded-lg border border-zinc-200 dark:border-zinc-700 text-zinc-700 dark:text-zinc-300 hover:bg-zinc-50 dark:hover:bg-zinc-800 transition-colors"
          >
            {gettext("Reset")}
          </button>
          <button
            :if={@variant == :floating}
            type="button"
            data-ai-chat-toggle
            aria-label={gettext("Close")}
            class="p-1.5 rounded-lg text-zinc-500 dark:text-zinc-400 hover:bg-zinc-100 dark:hover:bg-zinc-800"
          >
            <.icon name="hero-x-mark" class="w-5 h-5" />
          </button>
        </div>
      </div>

      <div
        class="flex-1 min-h-0 overflow-y-auto scroll-smooth px-4 py-4 space-y-4"
        id={"ai-messages-" <> @id}
        phx-hook="AiAutoScroll"
      >
        <div
          id={"ai-messages-stream-" <> @id}
          phx-update="stream"
          class="space-y-4"
        >
          <div
            :for={{dom_id, message} <- @streams.messages}
            id={dom_id}
            class={["flex", message.role == "user" && "justify-end"]}
          >
            <div class={[
              "max-w-[85%] rounded-xl px-4 py-3 text-sm break-words",
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

        <div
          :if={@thinking && !@streaming}
          id={"ai-thinking-" <> @id}
          class="flex items-center gap-1.5"
          role="status"
          data-ai-thinking
        >
          <span class="w-2 h-2 rounded-full bg-zinc-400 animate-bounce"></span>
          <span class="w-2 h-2 rounded-full bg-zinc-400 animate-bounce" style="animation-delay: 0.15s"></span>
          <span class="w-2 h-2 rounded-full bg-zinc-400 animate-bounce" style="animation-delay: 0.3s"></span>
        </div>

        <div :if={@streaming} class="flex">
          <div class="max-w-[85%] rounded-xl px-4 py-3 text-sm bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-800 dark:text-zinc-100 md-content">
            {TrebyWeb.Markdown.to_safe_html(@streaming_text)}
            <span class="inline-block w-1.5 h-4 align-middle bg-zinc-400 animate-pulse"></span>
          </div>
        </div>

        <div
          :if={@pending_runs != []}
          class="space-y-3"
        >
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
                :if={run.tool != "propose_form_fill"}
                type="button"
                id={"confirm-" <> run.id}
                phx-target={@myself}
                phx-click="confirm_tool_run"
                phx-value-id={run.id}
                class="px-3 py-1.5 text-sm font-medium rounded-lg bg-orange-700 text-white hover:bg-orange-800 transition-colors"
              >
                {gettext("Confirm")}
              </button>
              <button
                type="button"
                id={"reject-" <> run.id}
                phx-target={@myself}
                phx-click="reject_tool_run"
                phx-value-id={run.id}
                class="px-3 py-1.5 text-sm font-medium rounded-lg border border-zinc-300 dark:border-zinc-600 text-zinc-700 dark:text-zinc-300 hover:bg-zinc-100 dark:hover:bg-zinc-700 transition-colors"
              >
                {gettext("Cancel")}
              </button>
            </div>
          </div>
        </div>
      </div>

      <div :if={@ai_error} class="px-4 pb-2 text-xs text-red-600 dark:text-red-400">
        {@ai_error}
      </div>

      <form
        id={"ai-form-" <> @id}
        phx-target={@myself}
        phx-submit="send_message"
        class="flex gap-2 border-t border-zinc-200 dark:border-zinc-700 px-4 py-3"
      >
        <input
          id={"ai-input-" <> @id}
          type="text"
          name="message"
          value={@message}
          autocomplete="off"
          required
          disabled={@thinking}
          placeholder={
            if(@thinking,
              do: gettext("The assistant is answering..."),
              else: gettext("Ask the assistant...")
            )
          }
          aria-busy={@thinking}
          class="flex-1 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-4 py-2.5 text-sm text-zinc-900 dark:text-zinc-100 focus:outline-none focus:ring-2 focus:ring-orange-500 disabled:opacity-50 disabled:cursor-not-allowed"
        />
        <button
          type="submit"
          id={"ai-send-" <> @id}
          disabled={@thinking}
          class="px-4 py-2.5 text-sm font-medium rounded-xl bg-orange-700 text-white hover:bg-orange-800 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {gettext("Send")}
        </button>
      </form>
    </div>
    """
  end
end
