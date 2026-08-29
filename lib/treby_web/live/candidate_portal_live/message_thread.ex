defmodule TrebyWeb.CandidatePortalLive.MessageThread do
  use TrebyWeb, :live_view

  alias Treby.CandidatePortal

  @impl true
  def mount(%{"id" => conversation_id, "tenant_slug" => slug}, session, socket) do
    case CandidatePortal.get_conversation(conversation_id) do
      nil ->
        {:ok, redirect(socket, to: ~p"/404")}

      conversation ->
        tenant = Treby.Tenants.get_tenant_by_slug!(slug)
        candidate = Treby.Repo.get!(Treby.Candidates.Candidate, session["candidate_id"])

        CandidatePortal.subscribe_to_conversation(conversation.id)

        {:ok,
         socket
         |> assign(:conversation, conversation)
         |> assign(:current_tenant, tenant)
         |> assign(:current_candidate, candidate)
         |> assign(:page_title, "Conversation")
         |> assign(:new_message, "")}
    end
  end

  @impl true
  def handle_info({:conversation_updated, _conversation_id}, socket) do
    conversation = CandidatePortal.get_conversation!(socket.assigns.conversation.id)
    {:noreply, assign(socket, :conversation, conversation)}
  end

  @impl true
  def handle_event("update_message", %{"message" => message}, socket) do
    {:noreply, assign(socket, :new_message, message)}
  end

  @impl true
  def handle_event("send_message", %{"message" => body}, socket) do
    conversation = socket.assigns.conversation

    CandidatePortal.send_message(%{
      sender_type: "candidate",
      body: body,
      message_type: "text",
      conversation_id: conversation.id
    })

    conversation = CandidatePortal.get_conversation!(conversation.id)

    {:noreply,
     socket
     |> assign(:conversation, conversation)
     |> assign(:new_message, "")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.candidate_portal
      flash={@flash}
      current_tenant={@current_tenant}
      current_candidate={@current_candidate}
    >
      <div class="max-w-4xl mx-auto px-4 py-8">
        <.link
          navigate={"/#{@current_tenant.slug}/portal/messages"}
          class="text-sm text-blue-600 hover:text-blue-800 mb-4 inline-block"
        >
          ← Back to messages
        </.link>

        <h1 class="text-2xl font-bold text-gray-900 dark:text-white mb-6">
          {@conversation.subject || "Conversation"}
        </h1>

        <div class="space-y-4 mb-6">
          <%= for message <- @conversation.messages do %>
            <div class={[
              "rounded-lg p-4 max-w-3xl",
              message.sender_type == "candidate" && "bg-blue-50 dark:bg-blue-900/20 ml-auto",
              message.sender_type == "recruiter" && "bg-gray-100 dark:bg-gray-800",
              message.sender_type == "system" &&
                "bg-gray-50 dark:bg-gray-800/50 mx-auto text-center text-sm text-gray-500"
            ]}>
              <p class="text-gray-900 dark:text-white">{message.body}</p>
              <p class="text-xs text-gray-400 mt-1">
                {Calendar.strftime(message.inserted_at, "%b %d, %H:%M")}
              </p>
            </div>
          <% end %>
        </div>

        <%= if @conversation.status != "closed" do %>
          <.form for={%{}} phx-submit="send_message" class="flex gap-2">
            <input
              type="text"
              name="message"
              value={@new_message}
              phx-change="update_message"
              placeholder="Type a message..."
              class="flex-1 rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-2 text-gray-900 dark:text-white bg-white dark:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
            <button
              type="submit"
              class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              Send
            </button>
          </.form>
        <% else %>
          <p class="text-center text-gray-500 dark:text-gray-400 text-sm">
            This conversation is closed.
          </p>
        <% end %>
      </div>
    </Layouts.candidate_portal>
    """
  end
end
