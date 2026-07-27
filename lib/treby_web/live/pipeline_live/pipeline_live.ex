defmodule TrebyWeb.PipelineLive do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Jobs}

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])
    jobs = Jobs.list_jobs(tenant.id)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(jobs: jobs)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <h1 class="text-2xl font-bold mb-8">{gettext("Pipeline")}</h1>

        <div :if={@jobs == []} class="text-center py-12">
          <p class="text-gray-500 mb-4">
            {gettext("No jobs yet. Create a job to get started with the pipeline.")}
          </p>
          <.link navigate={~p"/app/jobs"} class="text-blue-600 hover:text-blue-800 font-medium">
            {gettext("Go to Jobs")}
          </.link>
        </div>

        <div :if={@jobs != []} class="grid gap-4">
          <div
            :for={job <- @jobs}
            class="bg-white rounded-lg border border-gray-200 p-4 hover:border-blue-300 transition-colors"
          >
            <.link navigate={~p"/app/pipeline/#{job.id}"} class="block">
              <div class="flex justify-between items-center">
                <div>
                  <h2 class="text-lg font-semibold text-gray-900">{job.title}</h2>
                  <p :if={job.location} class="text-sm text-gray-500">{job.location}</p>
                </div>
                <.icon name="hero-chevron-right" class="w-5 h-5 text-gray-400 inline" />
              </div>
            </.link>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
