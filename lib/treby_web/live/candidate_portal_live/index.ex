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
        <.page_header title={gettext("Your Applications")} />

        <%= if @selected_application do %>
          <.card class="mb-6">
            <div class="flex justify-between items-start mb-4">
              <div>
                <h2 class="text-xl font-semibold text-base-content">
                  {@selected_application.job.title}
                </h2>
                <p class="text-sm text-base-content/60">
                  {@selected_application.job.description}
                </p>
              </div>
              <.button
                phx-click="close_detail"
                aria-label={gettext("Close")}
                variant="ghost"
                size="sm"
                class="min-h-[44px] min-w-[44px]"
              >
                ✕
              </.button>
            </div>

            <div class="mb-4">
              <.status_badge status={@selected_application.pipeline_stage.name} />
            </div>

            <div class="bg-base-200 rounded-lg border border-base-300 p-4 mb-4">
              <p class="text-sm font-medium text-base-content mb-1">
                {gettext("Where you are")}
              </p>
              <p class="text-sm text-base-content/70">
                {candidate_step(@selected_application)}
              </p>

              <%= if @selected_action do %>
                <div class="mt-3 flex items-center justify-between gap-3 rounded-md bg-info/10 border border-info/20 px-3 py-2">
                  <p class="text-sm text-info-content">
                    <span class="font-medium">{gettext("Action needed:")}</span> {@selected_action.label}
                  </p>
                  <.link
                    navigate={@selected_action.link}
                    class="shrink-0 text-sm font-medium text-primary hover:underline"
                  >
                    Reply now →
                  </.link>
                </div>
              <% end %>
            </div>

            <div class="border-t border-base-300 pt-4">
              <div class="flex flex-wrap gap-4 text-sm text-base-content/50">
                <p>
                  Applied {Calendar.strftime(@selected_application.applied_at, "%b %d, %Y")}
                </p>
                <%= if @selected_application.source do %>
                  <p>Via {String.capitalize(@selected_application.source)}</p>
                <% end %>
              </div>
            </div>

            <%= if @selected_timeline != [] do %>
              <div class="border-t border-base-300 pt-4 mt-4">
                <p class="text-sm font-medium text-base-content mb-3">
                  Timeline
                </p>
                <div class="space-y-3">
                  <%= for entry <- @selected_timeline do %>
                    <div class="flex items-start gap-3">
                      <div class="mt-1.5 w-2 h-2 rounded-full bg-primary shrink-0"></div>
                      <div>
                        <p class="text-sm text-base-content/80">{entry.body}</p>
                        <p class="text-xs text-base-content/40">
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
                <div class="border-t border-base-300 pt-4 mt-4">
                  <div class="flex items-center justify-between mb-3">
                    <p class="text-sm font-medium text-base-content">
                      {active.subject || "Conversation"}
                    </p>
                    <.link
                      navigate={"/#{@current_tenant.slug}/portal/messages/#{active.id}"}
                      class="text-sm text-primary hover:underline"
                    >
                      Open full thread →
                    </.link>
                  </div>

                  <div class="space-y-2 max-h-64 overflow-y-auto mb-3 pr-1">
                    <%= for message <- active.messages do %>
                      <div class={[
                        "rounded-lg p-3 max-w-3xl",
                        message.sender_type == "candidate" && "bg-primary/10 ml-auto",
                        message.sender_type == "recruiter" && "bg-base-200",
                        message.sender_type == "system" &&
                          "bg-base-200/50 mx-auto text-center text-xs text-base-content/50"
                      ]}>
                        <p class="text-sm text-base-content">{message.body}</p>
                        <p class="text-xs text-base-content/40 mt-0.5">
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
                      class="input flex-1"
                    />
                    <.button type="submit" variant="primary" size="sm">
                      Send
                    </.button>
                  </form>
                </div>
              <% end %>
            <% end %>
          </.card>
        <% end %>

        <%= if @applications == [] do %>
          <.empty_state
            icon="hero-inbox"
            title={gettext("No applications yet.")}
            description={gettext("Browse open positions to apply.")}
          >
            <:cta>
              <.button variant="primary" navigate={"/#{@current_tenant.slug}/careers"}>
                Browse open positions →
              </.button>
            </:cta>
          </.empty_state>
        <% else %>
          <div class="space-y-4">
            <%= for application <- @applications do %>
              <button
                phx-click="select_application"
                phx-value-id={application.id}
                class="w-full text-left p-4 bg-base-100 rounded-lg border border-base-300 hover:border-primary transition-colors shadow-sm"
              >
                <div class="flex justify-between items-start">
                  <div>
                    <p class="font-medium text-base-content">
                      {application.job.title}
                    </p>
                    <p class="text-sm text-base-content/60 line-clamp-2">
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
    <.badge variant={badge_variant(@status)}>{human_status(@status)}</.badge>
    """
  end

  defp badge_variant("new"), do: "default"
  defp badge_variant("screening"), do: "info"
  defp badge_variant("interview"), do: "warning"
  defp badge_variant("offer"), do: "success"
  defp badge_variant("hired"), do: "success"
  defp badge_variant("rejected"), do: "danger"
  defp badge_variant(_), do: "default"

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
