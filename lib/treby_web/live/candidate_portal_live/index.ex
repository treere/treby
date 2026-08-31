defmodule TrebyWeb.CandidatePortalLive.Index do
  use TrebyWeb, :live_view

  alias Treby.Pipeline

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
       |> redirect(to: "/#{real_tenant.slug}/portal")}
    else
      applications = Pipeline.list_applications_for_candidate(tenant_id, candidate_id)

      Treby.CandidatePortal.subscribe_to_candidate_conversations(candidate_id)

      {:ok,
       socket
       |> assign(:applications, applications)
       |> assign(:current_tenant, tenant)
       |> assign(:current_candidate, candidate)
       |> assign(:page_title, "Dashboard")
       |> assign(:selected_application, nil)
       |> assign(:selected_action, nil)
       |> assign(:selected_conversations, [])
       |> assign(:selected_timeline, [])
       |> assign(:selected_draft, "")}
    end
  end

  @impl true
  def handle_event("select_application", %{"id" => id}, socket) do
    tenant_id = socket.assigns.current_tenant.id
    candidate_id = socket.assigns.current_candidate.id

    case Pipeline.get_application_for_candidate(tenant_id, candidate_id, id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Application not found."))}

      application ->
        conversations =
          Treby.CandidatePortal.list_conversations_for_application(application.id, tenant_id)

        {:noreply,
         assign(socket,
           selected_application: application,
           selected_action:
             candidate_pending_action(application, socket.assigns.current_tenant.slug),
           selected_conversations: conversations,
           selected_timeline: status_timeline(conversations),
           selected_draft: ""
         )}
    end
  end

  @impl true
  def handle_event("close_detail", _, socket) do
    {:noreply,
     assign(socket,
       selected_application: nil,
       selected_action: nil,
       selected_conversations: [],
       selected_timeline: [],
       selected_draft: ""
     )}
  end

  @impl true
  def handle_event("update_detail_draft", %{"message" => message}, socket) do
    {:noreply, assign(socket, :selected_draft, message)}
  end

  @impl true
  def handle_event(
        "send_detail_message",
        %{"conversation_id" => conversation_id, "message" => body},
        socket
      ) do
    body = String.trim(body)

    if body != "" do
      Treby.CandidatePortal.send_message(%{
        sender_type: "candidate",
        body: body,
        message_type: "text",
        conversation_id: conversation_id
      })
    end

    application = socket.assigns.selected_application
    tenant_id = socket.assigns.current_tenant.id

    conversations =
      Treby.CandidatePortal.list_conversations_for_application(application.id, tenant_id)

    {:noreply,
     assign(socket,
       selected_conversations: conversations,
       selected_timeline: status_timeline(conversations),
       selected_action: candidate_pending_action(application, socket.assigns.current_tenant.slug),
       selected_draft: ""
     )}
  end

  @impl true
  def handle_info({:conversation_updated, _conversation_id}, socket) do
    socket =
      case socket.assigns.selected_application do
        nil ->
          socket

        application ->
          tenant_id = socket.assigns.current_tenant.id

          conversations =
            Treby.CandidatePortal.list_conversations_for_application(application.id, tenant_id)

          assign(socket,
            selected_conversations: conversations,
            selected_timeline: status_timeline(conversations)
          )
      end

    {:noreply, socket}
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
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white mb-6">
          {gettext("Your Applications")}
        </h1>

        <%= if @selected_application do %>
          <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6 mb-6">
            <div class="flex justify-between items-start mb-4">
              <div>
                <h2 class="text-xl font-semibold text-gray-900 dark:text-white">
                  {@selected_application.job.title}
                </h2>
                <p class="text-sm text-gray-500 dark:text-gray-400">
                  {@selected_application.job.description}
                </p>
              </div>
              <button
                phx-click="close_detail"
                aria-label={gettext("Close")}
                class="text-gray-400 hover:text-gray-600 min-h-[44px] min-w-[44px] flex items-center justify-center rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
              >
                ✕
              </button>
            </div>

            <div class="mb-4">
              <.status_badge status={@selected_application.pipeline_stage.name} />
            </div>

            <div class="bg-gray-50 dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-700 p-4 mb-4">
              <p class="text-sm font-medium text-gray-900 dark:text-white mb-1">
                {gettext("Where you are")}
              </p>
              <p class="text-sm text-gray-600 dark:text-gray-300">
                {candidate_step(@selected_application)}
              </p>

              <%= if @selected_action do %>
                <div class="mt-3 flex items-center justify-between gap-3 rounded-md bg-blue-50 dark:bg-blue-950 border border-blue-200 dark:border-blue-900 px-3 py-2">
                  <p class="text-sm text-blue-800 dark:text-blue-200">
                    <span class="font-medium">{gettext("Action needed:")}</span> {@selected_action.label}
                  </p>
                  <.link
                    navigate={@selected_action.link}
                    class="shrink-0 text-sm font-medium text-blue-700 dark:text-blue-300 hover:underline"
                  >
                    Reply now →
                  </.link>
                </div>
              <% end %>
            </div>

            <div class="border-t border-gray-200 dark:border-gray-700 pt-4">
              <div class="flex flex-wrap gap-4 text-sm text-gray-500 dark:text-gray-400">
                <p>
                  Applied {Calendar.strftime(@selected_application.applied_at, "%b %d, %Y")}
                </p>
                <%= if @selected_application.source do %>
                  <p>Via {String.capitalize(@selected_application.source)}</p>
                <% end %>
              </div>
            </div>

            <%= if @selected_timeline != [] do %>
              <div class="border-t border-gray-200 dark:border-gray-700 pt-4 mt-4">
                <p class="text-sm font-medium text-gray-900 dark:text-white mb-3">
                  Timeline
                </p>
                <div class="space-y-3">
                  <%= for entry <- @selected_timeline do %>
                    <div class="flex items-start gap-3">
                      <div class="mt-1.5 w-2 h-2 rounded-full bg-blue-500 shrink-0"></div>
                      <div>
                        <p class="text-sm text-gray-700 dark:text-gray-300">{entry.body}</p>
                        <p class="text-xs text-gray-400">
                          {Calendar.strftime(entry.inserted_at, "%b %d, %Y")}
                        </p>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>

            <%= if @selected_conversations != [] do %>
              <% active = Enum.find(@selected_conversations, &(&1.status != "closed")) %>
              <%= if active do %>
                <div class="border-t border-gray-200 dark:border-gray-700 pt-4 mt-4">
                  <div class="flex items-center justify-between mb-3">
                    <p class="text-sm font-medium text-gray-900 dark:text-white">
                      {active.subject || "Conversation"}
                    </p>
                    <.link
                      navigate={"/#{@current_tenant.slug}/portal/messages/#{active.id}"}
                      class="text-sm text-blue-600 hover:text-blue-800"
                    >
                      Open full thread →
                    </.link>
                  </div>

                  <div class="space-y-2 max-h-64 overflow-y-auto mb-3 pr-1">
                    <%= for message <- active.messages do %>
                      <div class={[
                        "rounded-lg p-3 max-w-3xl",
                        message.sender_type == "candidate" && "bg-blue-50 dark:bg-blue-900/20 ml-auto",
                        message.sender_type == "recruiter" && "bg-gray-100 dark:bg-gray-800",
                        message.sender_type == "system" &&
                          "bg-gray-50 dark:bg-gray-800/50 mx-auto text-center text-xs text-gray-500"
                      ]}>
                        <p class="text-sm text-gray-900 dark:text-white">{message.body}</p>
                        <p class="text-xs text-gray-400 mt-0.5">
                          {Calendar.strftime(message.inserted_at, "%b %d, %H:%M")}
                        </p>
                      </div>
                    <% end %>
                  </div>

                  <form
                    phx-submit="send_detail_message"
                    class="flex gap-2"
                  >
                    <input type="hidden" name="conversation_id" value={active.id} />
                    <input
                      type="text"
                      name="message"
                      value={@selected_draft}
                      phx-change="update_detail_draft"
                      placeholder={gettext("Type a message...")}
                      class="flex-1 rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 text-sm text-gray-900 dark:text-white bg-white dark:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                    <button
                      type="submit"
                      class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 text-sm"
                    >
                      Send
                    </button>
                  </form>
                </div>
              <% end %>
            <% end %>
          </div>
        <% end %>

        <%= if @applications == [] do %>
          <div class="text-center py-12">
            <p class="text-gray-500 dark:text-gray-400">{gettext("No applications yet.")}</p>
            <.link
              navigate={"/#{@current_tenant.slug}/careers"}
              class="mt-4 inline-block text-blue-600 hover:text-blue-800"
            >
              Browse open positions →
            </.link>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for application <- @applications do %>
              <button
                phx-click="select_application"
                phx-value-id={application.id}
                class="w-full text-left p-4 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 hover:border-blue-500 transition-colors"
              >
                <div class="flex justify-between items-start">
                  <div>
                    <p class="font-medium text-gray-900 dark:text-white">
                      {application.job.title}
                    </p>
                    <p class="text-sm text-gray-500 dark:text-gray-400">
                      {application.job.description}
                    </p>
                  </div>
                  <.status_badge status={application.pipeline_stage.name} />
                </div>
              </button>
            <% end %>
          </div>
        <% end %>
      </div>
    </Layouts.candidate_portal>
    """
  end

  defp status_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
      @status == "new" && "bg-gray-100 text-gray-800",
      @status == "screening" && "bg-blue-100 text-blue-800",
      @status == "interview" && "bg-yellow-100 text-yellow-800",
      @status == "offer" && "bg-green-100 text-green-800",
      @status == "hired" && "bg-green-100 text-green-800",
      @status == "rejected" && "bg-red-100 text-red-800"
    ]}>
      {human_status(@status)}
    </span>
    """
  end

  defp human_status("new"), do: gettext("Received")
  defp human_status("screening"), do: gettext("Screening")
  defp human_status("interview"), do: gettext("Interview")
  defp human_status("offer"), do: gettext("Offer")
  defp human_status("hired"), do: gettext("Hired")
  defp human_status("rejected"), do: gettext("Not selected")
  defp human_status(other), do: String.capitalize(other)

  defp status_timeline(conversations) do
    conversations
    |> Enum.flat_map(& &1.messages)
    |> Enum.filter(&(&1.sender_type == "system" and &1.message_type == "status_update"))
    |> Enum.sort_by(& &1.inserted_at)
    |> Enum.map(&%{body: &1.body, inserted_at: &1.inserted_at})
  end

  defp candidate_step(application) do
    state = Pipeline.current_state(application)
    stage = state.stage
    interviews = state.progress.interviews

    cond do
      stage.stage_type == "rejected" ->
        gettext("We're sorry, but we've decided to move forward with other candidates.")

      stage.stage_type == "hired" ->
        gettext("Congratulations! You've been hired.")

      stage.stage_type == "offer" ->
        gettext("We've sent you an offer. You can review it in your messages.")

      stage.stage_type == "interview" and interviews.scheduled > 0 and interviews.completed == 0 ->
        gettext("You have an interview scheduled. We'll share the details and next steps here.")

      stage.stage_type == "interview" and interviews.completed > 0 ->
        gettext("Your interview is complete. We'll be in touch with next steps.")

      true ->
        gettext("Your application is under review.")
    end
  end

  defp candidate_pending_action(application, tenant_slug) do
    import Ecto.Query

    conversation =
      Treby.CandidatePortal.Conversation
      |> where([c], c.application_id == ^application.id and c.status == "open")
      |> order_by([c], desc: c.last_message_at)
      |> limit(1)
      |> preload(:messages)
      |> Treby.Repo.one()

    case conversation do
      %{messages: messages} when messages != [] ->
        last = List.last(messages)

        if last.sender_type == "recruiter" do
          subject = conversation.subject || "your application"

          %{
            label: "Reply to the recruiter about \"#{subject}\"",
            link: "/#{tenant_slug}/portal/messages/#{conversation.id}"
          }
        end

      _ ->
        nil
    end
  end
end
