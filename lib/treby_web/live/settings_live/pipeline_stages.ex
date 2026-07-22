defmodule TrebyWeb.SettingsLive.PipelineStages do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Pipeline}
  alias Treby.Pipeline.PipelineStage

  def mount(%{"id" => pipeline_id}, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])
    pipeline = Pipeline.get_pipeline!(pipeline_id)
    stages = Pipeline.list_pipeline_stages(pipeline_id)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(pipeline: pipeline)
     |> assign(stages: stages)
     |> assign(show_form: false)
     |> assign(editing_stage: nil)
     |> assign(deleting_stage: nil)
     |> assign(form: to_form(new_stage_changeset(pipeline_id)))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8 max-w-4xl">
        <div class="mb-8">
          <.link
            navigate={~p"/app/settings/pipeline"}
            class="text-blue-600 hover:text-blue-900 text-sm"
          >
            &larr; {gettext("Pipelines")}
          </.link>
          <h1 class="text-2xl font-bold mt-2">{@pipeline.name}</h1>
          <p class="mt-1 text-gray-600">{gettext("Configure stages for this pipeline")}</p>
        </div>

        <div :if={@show_form} class="mb-8 p-6 bg-white rounded-lg shadow">
          <h2 class="text-lg font-semibold mb-4">
            {if @editing_stage, do: gettext("Edit Stage"), else: gettext("New Stage")}
          </h2>
          <.form
            for={@form}
            id="stage-form"
            phx-submit="save_stage"
            class="flex gap-4 items-end flex-wrap"
          >
            <.input
              field={@form[:name]}
              type="text"
              label={gettext("Name")}
              placeholder={gettext("e.g. Technical Interview")}
            />
            <.input
              field={@form[:stage_type]}
              type="select"
              label={gettext("Type")}
              options={stage_type_options()}
            />
            <.input field={@form[:color]} type="color" label={gettext("Color")} />
            <div class="flex gap-2">
              <.button type="submit">{gettext("Save")}</.button>
              <.button type="button" phx-click="cancel_form" class="bg-gray-500">
                {gettext("Cancel")}
              </.button>
            </div>
          </.form>
        </div>

        <div
          :if={@deleting_stage}
          class="mb-8 p-6 bg-white rounded-lg shadow border-l-4 border-yellow-400"
        >
          <h2 class="text-lg font-semibold mb-2">{gettext("Reassign candidates")}</h2>
          <p class="text-gray-600 mb-4">
            {gettext("%{count} candidates are in \"%{stage}\". Move them to:",
              count: @deleting_stage.active_count,
              stage: @deleting_stage.name
            )}
          </p>
          <.form
            for={%{}}
            id="reassign-form"
            phx-submit="confirm_reassign"
            class="flex gap-4 items-end"
          >
            <.input
              name="target_stage_id"
              type="select"
              label={gettext("Move to")}
              options={Enum.map(@stages, &{&1.name, &1.id})}
              prompt={gettext("Select a stage")}
            />
            <div class="flex gap-2">
              <.button type="submit">{gettext("Move & Delete")}</.button>
              <.button type="button" phx-click="cancel_delete" class="bg-gray-500">
                {gettext("Cancel")}
              </.button>
            </div>
          </.form>
        </div>

        <div class="bg-white rounded-lg shadow overflow-hidden">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  {gettext("Color")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  {gettext("Name")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  {gettext("Type")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  {gettext("Position")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  {gettext("Actions")}
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr :for={{stage, idx} <- Enum.with_index(@stages)} class="hover:bg-gray-50">
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="w-6 h-6 rounded-full" style={"background-color: #{stage.color}"} />
                </td>
                <td class="px-6 py-4 whitespace-nowrap font-medium text-gray-900">
                  {stage.name}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-gray-600">
                  <span
                    :if={stage.stage_type}
                    class="inline-flex items-center rounded-md bg-gray-100 px-2 py-1 text-xs font-medium text-gray-600"
                  >
                    {stage.stage_type}
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-gray-600">
                  {stage.position}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <button
                    :if={idx > 0}
                    phx-click="move_stage_up"
                    phx-value-stage_id={stage.id}
                    class="text-gray-600 hover:text-gray-900 mr-2"
                  >
                    &uarr;
                  </button>
                  <button
                    :if={idx < length(@stages) - 1}
                    phx-click="move_stage_down"
                    phx-value-stage_id={stage.id}
                    class="text-gray-600 hover:text-gray-900 mr-2"
                  >
                    &darr;
                  </button>
                  <button
                    phx-click="edit_stage"
                    phx-value-stage_id={stage.id}
                    class="text-blue-600 hover:text-blue-900 mr-2"
                  >
                    {gettext("Edit")}
                  </button>
                  <button
                    phx-click="delete_stage"
                    phx-value-stage_id={stage.id}
                    class="text-red-600 hover:text-red-900"
                  >
                    {gettext("Delete")}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="mt-4">
          <button
            phx-click="show_create_form"
            class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
          >
            + {gettext("Add Stage")}
          </button>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("show_create_form", _, socket) do
    form = to_form(new_stage_changeset(socket.assigns.pipeline.id))
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
    pipeline_id = socket.assigns.pipeline.id
    max_position = length(socket.assigns.stages)

    attrs =
      stage_params
      |> Map.put("pipeline_id", pipeline_id)
      |> Map.put_new("position", max_position)
      |> Map.put_new("color", "#3b82f6")

    result =
      case socket.assigns.editing_stage do
        nil -> Pipeline.create_pipeline_stage(attrs)
        stage -> Pipeline.update_pipeline_stage(stage, stage_params)
      end

    case result do
      {:ok, _stage} ->
        stages = Pipeline.list_pipeline_stages(pipeline_id)

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
    active_count = Pipeline.active_applications_count(stage.id)
    stages = socket.assigns.stages

    cond do
      stage.stage_type == "new" and
          Enum.count(stages, &(&1.stage_type == "new")) == 1 ->
        {:noreply, put_flash(socket, :error, "Cannot delete the only entry stage.")}

      active_count > 0 ->
        deleting_stage = %{id: stage.id, name: stage.name, active_count: active_count}
        {:noreply, assign(socket, deleting_stage: deleting_stage)}

      true ->
        Pipeline.delete_pipeline_stage(stage)
        stages = Pipeline.list_pipeline_stages(socket.assigns.pipeline.id)
        {:noreply, socket |> assign(stages: stages) |> put_flash(:info, "Stage deleted")}
    end
  end

  def handle_event("confirm_reassign", %{"target_stage_id" => target_id}, socket) do
    stage = Pipeline.get_pipeline_stage!(socket.assigns.deleting_stage.id)
    Pipeline.reassign_and_delete_stage(stage, target_id)
    stages = Pipeline.list_pipeline_stages(socket.assigns.pipeline.id)

    {:noreply,
     socket
     |> assign(stages: stages, deleting_stage: nil)
     |> put_flash(:info, "Candidates reassigned and stage deleted")}
  end

  def handle_event("cancel_delete", _, socket) do
    {:noreply, assign(socket, deleting_stage: nil)}
  end

  def handle_event("move_stage_up", %{"stage_id" => stage_id}, socket) do
    stages = socket.assigns.stages
    idx = Enum.find_index(stages, &(&1.id == stage_id))

    if idx > 0 do
      above = Enum.at(stages, idx - 1)
      current = Enum.at(stages, idx)
      Pipeline.update_pipeline_stage(above, %{position: current.position})
      Pipeline.update_pipeline_stage(current, %{position: above.position})
      stages = Pipeline.list_pipeline_stages(socket.assigns.pipeline.id)
      {:noreply, assign(socket, stages: stages)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("move_stage_down", %{"stage_id" => stage_id}, socket) do
    stages = socket.assigns.stages
    idx = Enum.find_index(stages, &(&1.id == stage_id))

    if idx < length(stages) - 1 do
      below = Enum.at(stages, idx + 1)
      current = Enum.at(stages, idx)
      Pipeline.update_pipeline_stage(below, %{position: current.position})
      Pipeline.update_pipeline_stage(current, %{position: below.position})
      stages = Pipeline.list_pipeline_stages(socket.assigns.pipeline.id)
      {:noreply, assign(socket, stages: stages)}
    else
      {:noreply, socket}
    end
  end

  defp new_stage_changeset(pipeline_id) do
    %PipelineStage{pipeline_id: pipeline_id}
    |> Pipeline.change_pipeline_stage()
  end

  defp stage_type_options do
    [
      {"", ""},
      {"New", "new"},
      {"Interview", "interview"},
      {"Offer", "offer"},
      {"Hired", "hired"},
      {"Rejected", "rejected"}
    ]
  end
end
