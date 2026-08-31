defmodule TrebyWeb.CandidatePortalLive.Messages do
  use TrebyWeb, :live_view

  alias Treby.CandidatePortal

  @impl true
  def mount(%{"tenant_slug" => slug}, session, socket) do
    candidate_id = session["candidate_id"]
    tenant_id = session["candidate_tenant_id"]
    tenant = Treby.Tenants.get_tenant_by_slug!(slug)
    candidate = Treby.Repo.get!(Treby.Candidates.Candidate, candidate_id)

    if tenant.id != candidate.tenant_id do
      real_tenant = Treby.Repo.get!(Treby.Tenants.Tenant, candidate.tenant_id)

      {:ok,
       socket
       |> put_flash(:error, gettext("Wrong workspace. Redirected to your portal."))
       |> redirect(to: "/#{real_tenant.slug}/portal/messages")}
    else
      conversations = CandidatePortal.list_conversations_for_candidate(candidate_id, tenant_id)

      CandidatePortal.subscribe_to_candidate_conversations(candidate_id)

      {:ok,
       socket
       |> assign(:conversations, conversations)
       |> assign(:current_tenant, tenant)
       |> assign(:current_candidate, candidate)
       |> assign(:page_title, "Messages")}
    end
  end

  @impl true
  def handle_info({:conversation_updated, _conversation_id}, socket) do
    conversations =
      CandidatePortal.list_conversations_for_candidate(
        socket.assigns.current_candidate.id,
        socket.assigns.current_tenant.id
      )

    {:noreply, assign(socket, :conversations, conversations)}
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
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white mb-6">{gettext("Messages")}</h1>

        <%= if @conversations == [] do %>
          <div class="text-center py-12">
            <p class="text-gray-500 dark:text-gray-400">{gettext("No messages yet.")}</p>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for conversation <- @conversations do %>
              <.link
                navigate={"/#{@current_tenant.slug}/portal/messages/#{conversation.id}"}
                class="block p-4 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 hover:border-blue-500 transition-colors"
              >
                <div class="flex justify-between items-start">
                  <div>
                    <p class="font-medium text-gray-900 dark:text-white">
                      {conversation.subject || "Conversation"}
                    </p>
                    <%= if last_msg = List.last(conversation.messages) do %>
                      <p class="text-sm text-gray-500 dark:text-gray-400 mt-1 line-clamp-1">
                        {last_msg.body}
                      </p>
                    <% end %>
                  </div>
                  <span class="text-xs text-gray-400">
                    <%= if conversation.last_message_at do %>
                      {Calendar.strftime(conversation.last_message_at, "%b %d")}
                    <% end %>
                  </span>
                </div>
              </.link>
            <% end %>
          </div>
        <% end %>
      </div>
    </Layouts.candidate_portal>
    """
  end
end
