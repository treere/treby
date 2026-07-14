defmodule TrebyWeb.JobsLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Jobs}
  alias Treby.Jobs.Job

  def mount(_params, session, socket) do
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])
    jobs = Jobs.list_jobs(tenant.id)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(jobs: jobs)
     |> assign(show_form: false)
     |> assign(form: to_form(Jobs.change_job(%Job{})))}
  end

  def render(assigns) do
    ~H"""
    <div class="p-8">
      <div class="flex justify-between items-center mb-8">
        <h1 class="text-2xl font-bold">Jobs</h1>
        <button
          phx-click="show_create_form"
          class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
        >
          + New Job
        </button>
      </div>

      <div :if={@show_form} class="mb-8 p-6 bg-white rounded-lg shadow">
        <h2 class="text-lg font-semibold mb-4">Create Job</h2>
        <.form for={@form} id="job-form" phx-submit="create_job">
          <.input field={@form[:title]} type="text" label="Title" />
          <.input field={@form[:description]} type="textarea" label="Description" />
          <.input
            field={@form[:salary_range]}
            type="text"
            label="Salary Range"
            placeholder="$100k-$150k"
          />
          <div class="mt-4 flex gap-2">
            <.button type="submit">Create</.button>
            <.button type="button" phx-click="hide_create_form" class="bg-gray-500">Cancel</.button>
          </div>
        </.form>
      </div>

      <div class="bg-white rounded-lg shadow overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Title
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Salary
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Status
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr :for={job <- @jobs} class="hover:bg-gray-50">
              <td class="px-6 py-4 whitespace-nowrap">
                <.link
                  navigate={~p"/app/pipeline/#{job.id}"}
                  class="text-blue-600 hover:text-blue-900 font-medium"
                >
                  {job.title}
                </.link>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-gray-600">
                {job.salary_range || "-"}
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{if job.status == "open", do: "bg-green-100 text-green-800", else: "bg-gray-100 text-gray-800"}"}>
                  {job.status}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                <.link
                  navigate={~p"/app/pipeline/#{job.id}"}
                  class="text-blue-600 hover:text-blue-900 mr-3"
                >
                  Pipeline
                </.link>
                <button
                  phx-click="toggle_status"
                  phx-value-job_id={job.id}
                  class="text-yellow-600 hover:text-yellow-900"
                >
                  {if job.status == "open", do: "Close", else: "Reopen"}
                </button>
              </td>
            </tr>
          </tbody>
        </table>
        <div :if={@jobs == []} class="p-8 text-center text-gray-500">
          No jobs yet. Create your first job posting!
        </div>
      </div>
    </div>
    """
  end

  def handle_event("show_create_form", _, socket) do
    {:noreply, assign(socket, show_form: true)}
  end

  def handle_event("hide_create_form", _, socket) do
    {:noreply, assign(socket, show_form: false)}
  end

  def handle_event("create_job", %{"job" => job_params}, socket) do
    attrs = Map.put(job_params, "tenant_id", socket.assigns.current_tenant.id)

    case Jobs.create_job(attrs) do
      {:ok, _job} ->
        jobs = Jobs.list_jobs(socket.assigns.current_tenant.id)

        {:noreply,
         socket
         |> assign(jobs: jobs, show_form: false)
         |> assign(form: to_form(Jobs.change_job(%Job{})))
         |> put_flash(:info, "Job created successfully")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("toggle_status", %{"job_id" => job_id}, socket) do
    job = Jobs.get_job!(socket.assigns.current_tenant.id, job_id)
    new_status = if job.status == "open", do: "closed", else: "open"

    case Jobs.update_job(job, %{status: new_status}) do
      {:ok, _job} ->
        jobs = Jobs.list_jobs(socket.assigns.current_tenant.id)
        {:noreply, assign(socket, jobs: jobs)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update job status")}
    end
  end
end
