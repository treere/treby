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

        cond do
          tenant.id != candidate.tenant_id ->
            real_tenant = Treby.Repo.get!(Treby.Tenants.Tenant, candidate.tenant_id)

            {:ok,
             socket
             |> put_flash(:error, gettext("Wrong workspace. Redirected to your portal."))
             |> redirect(to: "/#{real_tenant.slug}/portal/messages")}

          conversation.tenant_id != candidate.tenant_id or
              conversation.candidate_id != candidate.id ->
            {:ok, redirect(socket, to: ~p"/404")}

          true ->
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
          class="text-sm text-primary hover:underline mb-4 inline-flex items-center gap-1"
        >
          ← Back to messages
        </.link>

        <.page_header title={@conversation.subject || "Conversation"} />

        <div class="space-y-4 mb-6">
          <%= for message <- @conversation.messages do %>
            <div class={[
              "rounded-lg p-4 max-w-3xl",
              message.sender_type == "candidate" && "bg-primary/10 ml-auto",
              message.sender_type == "recruiter" && "bg-base-200",
              message.sender_type == "system" &&
                "bg-base-200/50 mx-auto text-center text-sm text-base-content/50"
            ]}>
              <p class="text-base-content">{message.body}</p>
              <p class="text-xs text-base-content/40 mt-1">
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
              placeholder={gettext("Type a message...")}
              class="input flex-1"
            />
            <.button type="submit" variant="primary">
              Send
            </.button>
          </.form>
        <% else %>
          <p class="text-center text-base-content/50 text-sm">
            This conversation is closed.
          </p>
        <% end %>
      </div>
    </Layouts.candidate_portal>
    """
  end
end
