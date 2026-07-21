defmodule TrebyWeb.SettingsLive.Pipeline do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Pipeline}
  alias Treby.Pipeline.PipelineStage

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])
    stages = Pipeline.list_pipeline_stages(tenant.id)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(stages: stages)
     |> assign(show_form: false)
     |> assign(editing_stage: nil)
     |> assign(
       form: to_form(Pipeline.change_pipeline_stage(%PipelineStage{tenant_id: tenant.id}))
     )}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <div class="flex justify-between items-center mb-8">
          <div>
            <.link navigate={~p"/app/settings"} class="text-blue-600 hover:text-blue-900 text-sm">
              &larr; Back to Settings
            </.link>
            <h1 class="text-2xl font-bold mt-2">Pipeline Stages</h1>
            <p class="mt-1 text-gray-600">Customize your hiring pipeline stages</p>
          </div>
          <button
            phx-click="show_create_form"
            class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
          >
            + Add Stage
          </button>
        </div>

        <div :if={@show_form} class="mb-8 p-6 bg-white rounded-lg shadow">
          <h2 class="text-lg font-semibold mb-4">
            {if @editing_stage, do: "Edit Stage", else: "New Stage"}
          </h2>
          <.form
            for={@form}
            id="stage-form"
            phx-submit="save_stage"
            class="flex gap-4 items-end"
          >
            <.input
              field={@form[:name]}
              type="text"
              label="Name"
              placeholder="e.g. Technical Interview"
            />
            <.input field={@form[:color]} type="color" label="Color" />
            <.input field={@form[:position]} type="number" label="Position" />
            <div class="flex gap-2">
              <.button type="submit">Save</.button>
              <.button type="button" phx-click="cancel_form" class="bg-gray-500">Cancel</.button>
            </div>
          </.form>
        </div>

        <div class="bg-white rounded-lg shadow overflow-hidden">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Color
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Name
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Position
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr :for={stage <- @stages} class="hover:bg-gray-50">
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="w-6 h-6 rounded-full" style={"background-color: #{stage.color}"}></div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap font-medium text-gray-900">{stage.name}</td>
                <td class="px-6 py-4 whitespace-nowrap text-gray-600">{stage.position}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <button
                    phx-click="edit_stage"
                    phx-value-stage_id={stage.id}
                    class="text-blue-600 hover:text-blue-900 mr-3"
                  >
                    Edit
                  </button>
                  <button
                    phx-click="delete_stage"
                    phx-value-stage_id={stage.id}
                    class="text-red-600 hover:text-red-900"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("show_create_form", _, socket) do
    form =
      to_form(
        Pipeline.change_pipeline_stage(%PipelineStage{
          tenant_id: socket.assigns.current_tenant.id
        })
      )

    {:noreply, assign(socket, show_form: true, editing_stage: nil, form: form)}
  end

  def handle_event("cancel_form", _, socket) do
    {:noreply, assign(socket, show_form: false, editing_stage: nil)}
  end

  def handle_event("edit_stage", %{"stage_id" => stage_id}, socket) do
    stage = Pipeline.get_pipeline_stage!(stage_id)
    form = to_form(Pipeline.change_pipeline_stage(stage))
    {:noreply, assign(socket, show_form: true, editing_stage: stage, form: form)}
  end

  def handle_event("save_stage", %{"pipeline_stage" => stage_params}, socket) do
    attrs = Map.put(stage_params, "tenant_id", socket.assigns.current_tenant.id)

    result =
      case socket.assigns.editing_stage do
        nil -> Pipeline.create_pipeline_stage(attrs)
        stage -> Pipeline.update_pipeline_stage(stage, stage_params)
      end

    case result do
      {:ok, _stage} ->
        stages = Pipeline.list_pipeline_stages(socket.assigns.current_tenant.id)

        {:noreply,
         socket
         |> assign(stages: stages, show_form: false, editing_stage: nil)
         |> put_flash(:info, "Stage saved")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("delete_stage", %{"stage_id" => stage_id}, socket) do
    stage = Pipeline.get_pipeline_stage!(stage_id)

    case Pipeline.delete_pipeline_stage(stage) do
      {:ok, _} ->
        stages = Pipeline.list_pipeline_stages(socket.assigns.current_tenant.id)
        {:noreply, socket |> assign(stages: stages) |> put_flash(:info, "Stage deleted")}

      {:error, :has_active_applications} ->
        {:noreply, put_flash(socket, :error, "Cannot delete stage with active candidates")}
    end
  end
end
