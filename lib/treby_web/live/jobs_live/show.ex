defmodule TrebyWeb.JobsLive.Show do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Jobs, Customization}

  def mount(%{"id" => id}, session, socket) do
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])
    job = Jobs.get_job!(tenant.id, id)
    job_fields = Customization.list_custom_fields_for(tenant.id, "job")

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(job: job)
     |> assign(job_fields: job_fields)
     |> assign(editing: false)
     |> assign(form: to_form(Jobs.change_job(job)))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user}>
      <div class="p-8">
        <div class="flex justify-between items-center mb-8">
          <div>
            <.link navigate={~p"/app/jobs"} class="text-blue-600 hover:text-blue-900 text-sm">
              &larr; Back to Jobs
            </.link>
            <h1 class="text-2xl font-bold mt-2">{@job.title}</h1>
          </div>
          <div class="flex gap-2">
            <button
              phx-click="start_editing"
              class="bg-gray-200 px-4 py-2 rounded-lg hover:bg-gray-300"
            >
              Edit
            </button>
            <.link
              navigate={~p"/app/pipeline/#{@job.id}"}
              class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
            >
              View Pipeline
            </.link>
          </div>
        </div>

        <div :if={@editing} class="mb-8 p-6 bg-white rounded-lg shadow">
          <h2 class="text-lg font-semibold mb-4">Edit Job</h2>
          <.form for={@form} id="job-edit-form" phx-submit="update_job">
            <.input field={@form[:title]} type="text" label="Title" />
            <.input field={@form[:description]} type="textarea" label="Description" />
            <.input field={@form[:salary_range]} type="text" label="Salary Range" />
            <.input field={@form[:status]} type="select" label="Status" options={["open", "closed"]} />

            <div :if={@job_fields != []} class="mt-4 border-t pt-4">
              <h3 class="text-sm font-medium text-gray-700 mb-3">Custom Fields</h3>
              <div :for={field <- @job_fields} class="mb-3">
                <%= cond do %>
                  <% field.field_type == "select" -> %>
                    <label class="block text-sm font-medium text-gray-700 mb-1">{field.name}</label>
                    <select
                      name={"custom_fields[#{field.id}]"}
                      class="block w-full rounded-lg border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
                    >
                      <option value="">—</option>
                      <option
                        :for={opt <- field.options}
                        value={opt}
                        selected={opt == Map.get(@job.custom_fields || %{}, field.id)}
                      >
                        {opt}
                      </option>
                    </select>
                  <% field.field_type == "date" -> %>
                    <.input
                      name={"custom_fields[#{field.id}]"}
                      type="date"
                      label={field.name}
                      value={Map.get(@job.custom_fields || %{}, field.id, "")}
                    />
                  <% field.field_type == "number" -> %>
                    <.input
                      name={"custom_fields[#{field.id}]"}
                      type="number"
                      label={field.name}
                      value={Map.get(@job.custom_fields || %{}, field.id, "")}
                    />
                  <% field.field_type == "url" -> %>
                    <.input
                      name={"custom_fields[#{field.id}]"}
                      type="url"
                      label={field.name}
                      value={Map.get(@job.custom_fields || %{}, field.id, "")}
                      placeholder="https://"
                    />
                  <% true -> %>
                    <.input
                      name={"custom_fields[#{field.id}]"}
                      type="text"
                      label={field.name}
                      value={Map.get(@job.custom_fields || %{}, field.id, "")}
                    />
                <% end %>
              </div>
            </div>

            <div class="mt-4 flex gap-2">
              <.button type="submit">Save</.button>
              <.button type="button" phx-click="cancel_editing" class="bg-gray-500">Cancel</.button>
            </div>
          </.form>
        </div>

        <div class="grid grid-cols-3 gap-6">
          <div class="col-span-2 bg-white rounded-lg shadow p-6">
            <h2 class="text-lg font-semibold mb-4">Description</h2>
            <p class="text-gray-700 whitespace-pre-wrap">{@job.description}</p>
          </div>
          <div class="bg-white rounded-lg shadow p-6">
            <h2 class="text-lg font-semibold mb-4">Details</h2>
            <dl class="space-y-4">
              <div>
                <dt class="text-sm text-gray-500">Salary Range</dt>
                <dd class="text-gray-900">{@job.salary_range || "Not specified"}</dd>
              </div>
              <div>
                <dt class="text-sm text-gray-500">Status</dt>
                <dd>
                  <span class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{if @job.status == "open", do: "bg-green-100 text-green-800", else: "bg-gray-100 text-gray-800"}"}>
                    {@job.status}
                  </span>
                </dd>
              </div>
              <div>
                <dt class="text-sm text-gray-500">Created</dt>
                <dd class="text-gray-900">{Calendar.strftime(@job.inserted_at, "%b %d, %Y")}</dd>
              </div>

              <div :if={@job_fields != []} class="border-t pt-4">
                <dt class="text-sm text-gray-500 mb-2">Custom Fields</dt>
                <dl class="space-y-2">
                  <div :for={field <- @job_fields}>
                    <dt class="text-xs text-gray-500">{field.name}</dt>
                    <dd class="text-sm text-gray-900">
                      {Map.get(@job.custom_fields || %{}, field.id, "—")}
                    </dd>
                  </div>
                </dl>
              </div>
            </dl>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("start_editing", _, socket) do
    {:noreply, assign(socket, editing: true)}
  end

  def handle_event("cancel_editing", _, socket) do
    {:noreply,
     socket
     |> assign(editing: false)
     |> assign(form: to_form(Jobs.change_job(socket.assigns.job)))}
  end

  def handle_event("update_job", params, socket) do
    job_params = Map.get(params, "job", %{})
    custom_fields_values = Map.get(params, "custom_fields", %{})

    required_fields =
      Customization.list_custom_fields_for(socket.assigns.current_tenant.id, "job")
      |> Enum.filter(& &1.required)
      |> Enum.filter(fn field ->
        value = Map.get(custom_fields_values, to_string(field.id), "")
        value == "" or is_nil(value)
      end)

    if required_fields != [] do
      missing = Enum.map_join(required_fields, ", ", & &1.name)

      {:noreply,
       socket
       |> put_flash(:error, "Please fill in required fields: #{missing}")}
    else
      attrs = Map.put(job_params, "custom_fields", custom_fields_values)

      case Jobs.update_job(socket.assigns.job, attrs) do
        {:ok, job} ->
          {:noreply,
           socket
           |> assign(job: job, editing: false)
           |> assign(form: to_form(Jobs.change_job(job)))
           |> put_flash(:info, "Job updated")}

        {:error, changeset} ->
          {:noreply, assign(socket, form: to_form(changeset))}
      end
    end
  end
end
