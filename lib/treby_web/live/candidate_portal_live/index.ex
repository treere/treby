defmodule TrebyWeb.CandidatePortalLive.Index do
  use TrebyWeb, :live_view

  alias Treby.Pipeline

  @impl true
  def mount(%{"tenant_slug" => slug}, session, socket) do
    candidate_id = session["candidate_id"]
    tenant_id = session["candidate_tenant_id"]
    tenant = Treby.Tenants.get_tenant_by_slug!(slug)
    candidate = Treby.Repo.get!(Treby.Candidates.Candidate, candidate_id)

    applications = Pipeline.list_applications_for_candidate(tenant_id, candidate_id)

    {:ok,
     socket
     |> assign(:applications, applications)
     |> assign(:current_tenant, tenant)
     |> assign(:current_candidate, candidate)
     |> assign(:page_title, "Dashboard")
     |> assign(:selected_application, nil)}
  end

  @impl true
  def handle_event("select_application", %{"id" => id}, socket) do
    application = Pipeline.get_application!(id)
    {:noreply, assign(socket, :selected_application, application)}
  end

  @impl true
  def handle_event("close_detail", _, socket) do
    {:noreply, assign(socket, :selected_application, nil)}
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
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white mb-6">Your Applications</h1>

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
                class="text-gray-400 hover:text-gray-600"
              >
                ✕
              </button>
            </div>

            <div class="mb-4">
              <.status_badge status={@selected_application.pipeline_stage.name} />
            </div>

            <div class="border-t border-gray-200 dark:border-gray-700 pt-4">
              <p class="text-sm text-gray-500 dark:text-gray-400">
                Applied {Calendar.strftime(@selected_application.applied_at, "%b %d, %Y")}
              </p>
            </div>
          </div>
        <% end %>

        <%= if @applications == [] do %>
          <div class="text-center py-12">
            <p class="text-gray-500 dark:text-gray-400">No applications yet.</p>
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
      {String.capitalize(@status)}
    </span>
    """
  end
end
