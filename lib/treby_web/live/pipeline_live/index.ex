defmodule TrebyWeb.PipelineLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Jobs, Pipeline}

  def mount(%{"job_id" => job_id}, session, socket) do
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])
    job = Jobs.get_job!(tenant.id, job_id)
    stages = Pipeline.list_pipeline_stages(tenant.id)
    applications_by_stage = Pipeline.list_applications_by_stage(job_id)

    if connected?(socket) do
      Pipeline.subscribe_to_pipeline(job_id)
    end

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(job: job)
     |> assign(stages: stages)
     |> assign(applications_by_stage: applications_by_stage)}
  end

  def handle_info({:pipeline_updated, job_id}, socket) do
    applications_by_stage = Pipeline.list_applications_by_stage(job_id)
    {:noreply, assign(socket, applications_by_stage: applications_by_stage)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user}>
      <div class="p-8">
        <div class="flex justify-between items-center mb-8">
          <div>
            <.link
              navigate={~p"/app/jobs/#{@job.id}"}
              class="text-blue-600 hover:text-blue-900 text-sm"
            >
              &larr; Back to Job
            </.link>
            <h1 class="text-2xl font-bold mt-2">{@job.title} - Pipeline</h1>
          </div>
        </div>

        <div class="flex gap-4 overflow-x-auto pb-4">
          <div
            :for={{stage, applications} <- @applications_by_stage}
            id={"stage-#{stage.id}"}
            class="flex-shrink-0 w-80 bg-gray-100 rounded-lg p-4"
            data-stage-id={stage.id}
          >
            <div class="flex items-center gap-2 mb-4">
              <div class="w-3 h-3 rounded-full" style={"background-color: #{stage.color}"}></div>
              <h3 class="font-semibold text-gray-800">{stage.name}</h3>
              <span class="ml-auto text-sm text-gray-500 bg-gray-200 px-2 py-0.5 rounded-full">
                {length(applications)}
              </span>
            </div>

            <div
              id={"stage-cards-#{stage.id}"}
              class="space-y-3 min-h-[100px]"
              phx-hook="Sortable"
              data-stage-id={stage.id}
            >
              <div
                :for={application <- applications}
                id={"application-#{application.id}"}
                class="bg-white rounded-lg p-4 shadow-sm cursor-move hover:shadow-md transition-shadow"
                data-application-id={application.id}
              >
                <p class="font-medium text-gray-900">{application.candidate.name}</p>
                <p class="text-sm text-gray-500">{application.candidate.email}</p>
                <a
                  :if={application.resume_url}
                  href={~p"/app/applications/#{application.id}/resume"}
                  class="text-xs text-blue-600 hover:text-blue-900 mt-1 inline-block"
                >
                  View Resume
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event(
        "move_candidate",
        %{"application_id" => application_id, "stage_id" => stage_id},
        socket
      ) do
    application = Pipeline.get_application!(application_id)

    case Pipeline.move_application(application, stage_id) do
      {:ok, _application} ->
        applications_by_stage = Pipeline.list_applications_by_stage(socket.assigns.job.id)
        {:noreply, assign(socket, applications_by_stage: applications_by_stage)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to move candidate")}
    end
  end
end
