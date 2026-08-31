defmodule TrebyWeb.SettingsLive.PipelineStages do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Pipeline}
  alias Treby.Pipeline.PipelineStage

  def mount(%{"id" => pipeline_id}, session, socket) do
    socket = set_locale_from_session(socket, session)

    {user, tenant} =
      cond do
        socket.assigns[:current_user] && socket.assigns[:current_tenant] ->
          {socket.assigns.current_user, socket.assigns.current_tenant}

        session["user_id"] && session["tenant_id"] ->
          {Accounts.get_user!(session["user_id"]), Tenants.get_tenant!(session["tenant_id"])}

        session["user_id"] ->
          u = Accounts.get_user!(session["user_id"])

          case Treby.Memberships.list_tenants_for_user(u.id) do
            [%{tenant: t} | _] -> {u, t}
            [] -> {u, nil}
          end

        true ->
          {nil, nil}
      end

    case Pipeline.get_pipeline(pipeline_id) do
      nil ->
        {:ok, redirect(socket, to: ~p"/404")}

      pipeline ->
        stages = Pipeline.list_pipeline_stages(pipeline_id)
        users = Accounts.list_users(tenant.id)

        stages_with_counts =
          Enum.map(stages, fn stage ->
            examiner_count = length(Pipeline.list_examiner_ids(stage))
            reviewer_count = length(Pipeline.list_reviewer_ids(stage))
            advancer_count = length(Pipeline.list_advancer_ids(stage))

            Map.merge(stage, %{
              examiner_count: examiner_count,
              reviewer_count: reviewer_count,
              advancer_count: advancer_count
            })
          end)

        {:ok,
         socket
         |> assign(current_user: user, current_tenant: tenant)
         |> assign(pipeline: pipeline)
         |> assign(stages: stages_with_counts)
         |> assign(users: users)
         |> assign(show_form: false)
         |> assign(editing_stage: nil)
         |> assign(deleting_stage: nil)
         |> assign(form: to_form(new_stage_changeset(pipeline_id)))}
    end
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
          <p class="mt-1 text-base-content/70">{gettext("Configure stages for this pipeline")}</p>
        </div>

        <div :if={@show_form} class="mb-8 p-6 bg-base-100 rounded-lg shadow">
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

            <div :if={@form[:stage_type].value == "interview"} class="w-full">
              <.input
                field={@form[:min_examiners]}
                type="number"
                label={gettext("Min Examiners Required")}
                min="1"
              />
              <.input
                field={@form[:scorecard_template_id]}
                type="select"
                label={gettext("Scorecard Template")}
                options={scorecard_template_options(@current_tenant.id)}
                prompt={gettext("None")}
              />
            </div>

            <div class="flex gap-2">
              <.button type="submit" variant="primary">{gettext("Save")}</.button>
              <.button type="button" phx-click="cancel_form" variant="ghost">
                {gettext("Cancel")}
              </.button>
            </div>
          </.form>
        </div>

        <div
          :if={@deleting_stage}
          class="mb-8 p-6 bg-base-100 rounded-lg shadow border-l-4 border-yellow-400"
        >
          <h2 class="text-lg font-semibold mb-2">{gettext("Reassign candidates")}</h2>
          <p class="text-base-content/70 mb-4">
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
              <.button type="submit" variant="primary">{gettext("Move & Delete")}</.button>
              <.button type="button" phx-click="cancel_delete" variant="ghost">
                {gettext("Cancel")}
              </.button>
            </div>
          </.form>
        </div>

        <div class="bg-base-100 rounded-lg shadow overflow-hidden">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-base-200">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  {gettext("Color")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  {gettext("Name")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  {gettext("Type")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  {gettext("Roles")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  {gettext("Actions")}
                </th>
              </tr>
            </thead>
            <tbody class="bg-base-100 divide-y divide-gray-200">
              <tr :for={{stage, idx} <- Enum.with_index(@stages)} class="hover:bg-base-200">
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="w-6 h-6 rounded-full" style={"background-color: #{stage.color}"} />
                </td>
                <td class="px-6 py-4 whitespace-nowrap font-medium text-base-content">
                  {stage.name}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-base-content/70">
                  <span
                    :if={stage.stage_type}
                    class="inline-flex items-center rounded-md bg-base-200 px-2 py-1 text-xs font-medium text-base-content/70"
                  >
                    {stage.stage_type}
                  </span>
                </td>
                <td class="px-6 py-4 text-sm text-base-content/70">
                  <div class="flex flex-wrap gap-1">
                    <span
                      :if={stage.stage_type == "interview" && stage.min_examiners > 1}
                      class="inline-flex items-center rounded-md bg-blue-100 px-2 py-0.5 text-xs font-medium text-blue-800"
                    >
                      {gettext("%{count} examiners", count: stage.min_examiners)}
                    </span>
                    <span
                      :if={stage.examiner_count > 0}
                      class="inline-flex items-center rounded-md bg-blue-50 px-2 py-0.5 text-xs font-medium text-blue-700"
                    >
                      {gettext("%{count}E", count: stage.examiner_count)}
                    </span>
                    <span
                      :if={stage.reviewer_count > 0}
                      class="inline-flex items-center rounded-md bg-green-50 px-2 py-0.5 text-xs font-medium text-green-700"
                    >
                      {gettext("%{count}R", count: stage.reviewer_count)}
                    </span>
                    <span
                      :if={stage.advancer_count > 0}
                      class="inline-flex items-center rounded-md bg-purple-50 px-2 py-0.5 text-xs font-medium text-purple-700"
                    >
                      {gettext("%{count}A", count: stage.advancer_count)}
                    </span>
                  </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <button
                    :if={idx > 0}
                    phx-click="move_stage_up"
                    phx-value-stage_id={stage.id}
                    class="text-base-content/70 hover:text-base-content mr-2"
                  >
                    &uarr;
                  </button>
                  <button
                    :if={idx < length(@stages) - 1}
                    phx-click="move_stage_down"
                    phx-value-stage_id={stage.id}
                    class="text-base-content/70 hover:text-base-content mr-2"
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
                    :if={stage.stage_type == "interview"}
                    phx-click="show_roles"
                    phx-value-stage_id={stage.id}
                    class="text-green-600 hover:text-green-900 mr-2"
                  >
                    {gettext("Roles")}
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
          <.button phx-click="show_create_form" variant="primary">
            + {gettext("Add Stage")}
          </.button>
        </div>

        <%!-- Role Assignment Modal --%>
        <div
          :if={@editing_roles}
          class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
          phx-click="close_roles"
        >
          <div
            class="bg-base-100 rounded-lg shadow-xl max-w-2xl w-full mx-4 max-h-[80vh] overflow-y-auto"
            phx-click=""
          >
            <div class="p-6">
              <h2 class="text-lg font-semibold mb-4">
                {gettext("Roles for")} {@editing_roles.name}
              </h2>

              <div class="mb-6">
                <h3 class="text-sm font-medium text-base-content/70 mb-2">{gettext("Examiners")}</h3>
                <div :if={@editing_roles.examiners != []} class="flex flex-wrap gap-2 mb-2">
                  <span
                    :for={examiner <- @editing_roles.examiners}
                    class="inline-flex items-center gap-1 rounded-md bg-blue-100 px-2 py-1 text-xs"
                  >
                    {examiner.user.name}
                    <button
                      phx-click="remove_examiner"
                      phx-value-stage_id={@editing_roles.id}
                      phx-value-user_id={examiner.user_id}
                      class="text-blue-600 hover:text-blue-900"
                    >
                      &times;
                    </button>
                  </span>
                </div>
                <.form
                  for={%{}}
                  id="add-examiner-form"
                  phx-submit="add_examiner"
                  class="flex gap-2"
                >
                  <input type="hidden" name="stage_id" value={@editing_roles.id} />
                  <.input
                    name="user_id"
                    type="select"
                    options={
                      Enum.map(available_users(@users, @editing_roles.examiners), &{&1.name, &1.id})
                    }
                    prompt={gettext("Select user...")}
                    label=""
                  />
                  <.button type="submit" variant="primary" size="sm">
                    {gettext("Add")}
                  </.button>
                </.form>
              </div>

              <div class="mb-6">
                <h3 class="text-sm font-medium text-base-content/70 mb-2">{gettext("Reviewers")}</h3>
                <div :if={@editing_roles.reviewers != []} class="flex flex-wrap gap-2 mb-2">
                  <span
                    :for={reviewer <- @editing_roles.reviewers}
                    class="inline-flex items-center gap-1 rounded-md bg-green-100 px-2 py-1 text-xs"
                  >
                    {reviewer.user.name}
                    <button
                      phx-click="remove_reviewer"
                      phx-value-stage_id={@editing_roles.id}
                      phx-value-user_id={reviewer.user_id}
                      class="text-green-600 hover:text-green-900"
                    >
                      &times;
                    </button>
                  </span>
                </div>
                <.form
                  for={%{}}
                  id="add-reviewer-form"
                  phx-submit="add_reviewer"
                  class="flex gap-2"
                >
                  <input type="hidden" name="stage_id" value={@editing_roles.id} />
                  <.input
                    name="user_id"
                    type="select"
                    options={
                      Enum.map(available_users(@users, @editing_roles.reviewers), &{&1.name, &1.id})
                    }
                    prompt={gettext("Select user...")}
                    label=""
                  />
                  <.button type="submit" variant="primary" size="sm">
                    {gettext("Add")}
                  </.button>
                </.form>
              </div>

              <div class="mb-6">
                <h3 class="text-sm font-medium text-base-content/70 mb-2">{gettext("Advancers")}</h3>
                <div :if={@editing_roles.advancers != []} class="flex flex-wrap gap-2 mb-2">
                  <span
                    :for={advancer <- @editing_roles.advancers}
                    class="inline-flex items-center gap-1 rounded-md bg-purple-100 px-2 py-1 text-xs"
                  >
                    {advancer.user.name}
                    <button
                      phx-click="remove_advancer"
                      phx-value-stage_id={@editing_roles.id}
                      phx-value-user_id={advancer.user_id}
                      class="text-purple-600 hover:text-purple-900"
                    >
                      &times;
                    </button>
                  </span>
                </div>
                <.form
                  for={%{}}
                  id="add-advancer-form"
                  phx-submit="add_advancer"
                  class="flex gap-2"
                >
                  <input type="hidden" name="stage_id" value={@editing_roles.id} />
                  <.input
                    name="user_id"
                    type="select"
                    options={
                      Enum.map(available_users(@users, @editing_roles.advancers), &{&1.name, &1.id})
                    }
                    prompt={gettext("Select user...")}
                    label=""
                  />
                  <.button type="submit" variant="secondary" size="sm">
                    {gettext("Add")}
                  </.button>
                </.form>
              </div>

              <div class="flex justify-end">
                <.button type="button" phx-click="close_roles">{gettext("Done")}</.button>
              </div>
            </div>
          </div>
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
        nil -> Pipeline.create_pipeline_stage(attrs, socket.assigns.current_user)
        stage -> Pipeline.update_pipeline_stage(stage, attrs, socket.assigns.current_user)
      end

    case result do
      {:ok, _stage} ->
        stages = reload_stages_with_counts(pipeline_id)

        {:noreply,
         socket
         |> assign(stages: stages, show_form: false, editing_stage: nil)
         |> put_flash(:info, gettext("Stage saved"))}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, gettext("Only admins can manage pipeline stages"))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(form: to_form(changeset))
         |> put_flash(:error, gettext("Please review the errors below"))}
    end
  end

  def handle_event("delete_stage", %{"stage_id" => stage_id}, socket) do
    stage = Pipeline.get_pipeline_stage!(stage_id)
    active_count = Pipeline.active_applications_count(stage.id)
    stages = socket.assigns.stages

    cond do
      stage.stage_type == "new" and
          Enum.count(stages, &(&1.stage_type == "new")) == 1 ->
        {:noreply, put_flash(socket, :error, gettext("Cannot delete the only entry stage."))}

      active_count > 0 ->
        deleting_stage = %{id: stage.id, name: stage.name, active_count: active_count}
        {:noreply, assign(socket, deleting_stage: deleting_stage)}

      true ->
        case Pipeline.delete_pipeline_stage(stage, socket.assigns.current_user) do
          {:ok, _} ->
            stages = reload_stages_with_counts(socket.assigns.pipeline.id)

            {:noreply,
             socket |> assign(stages: stages) |> put_flash(:info, gettext("Stage deleted"))}

          {:error, :unauthorized} ->
            {:noreply,
             put_flash(socket, :error, gettext("Only admins can delete pipeline stages"))}
        end
    end
  end

  def handle_event("confirm_reassign", %{"target_stage_id" => target_id}, socket) do
    stage = Pipeline.get_pipeline_stage!(socket.assigns.deleting_stage.id)
    Pipeline.reassign_and_delete_stage(stage, target_id)
    stages = reload_stages_with_counts(socket.assigns.pipeline.id)

    {:noreply,
     socket
     |> assign(stages: stages, deleting_stage: nil)
     |> put_flash(:info, gettext("Candidates reassigned and stage deleted"))}
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

      Pipeline.update_pipeline_stage(
        above,
        %{position: current.position},
        socket.assigns.current_user
      )

      Pipeline.update_pipeline_stage(
        current,
        %{position: above.position},
        socket.assigns.current_user
      )

      stages = reload_stages_with_counts(socket.assigns.pipeline.id)
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

      Pipeline.update_pipeline_stage(
        below,
        %{position: current.position},
        socket.assigns.current_user
      )

      Pipeline.update_pipeline_stage(
        current,
        %{position: below.position},
        socket.assigns.current_user
      )

      stages = reload_stages_with_counts(socket.assigns.pipeline.id)
      {:noreply, assign(socket, stages: stages)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("show_roles", %{"stage_id" => stage_id}, socket) do
    stage = Pipeline.get_pipeline_stage!(stage_id)

    examiners = Pipeline.list_examiners(stage)
    reviewers = Pipeline.list_reviewers(stage)
    advancers = Pipeline.list_advancers(stage)

    editing_roles = %{stage | examiners: examiners, reviewers: reviewers, advancers: advancers}

    {:noreply, assign(socket, editing_roles: editing_roles)}
  end

  def handle_event("close_roles", _, socket) do
    {:noreply, assign(socket, editing_roles: nil)}
  end

  def handle_event("add_examiner", %{"stage_id" => stage_id, "user_id" => user_id}, socket) do
    stage = Pipeline.get_pipeline_stage!(stage_id)
    Pipeline.assign_examiner(stage, user_id)
    editing_roles = refresh_roles(socket.assigns.editing_roles)
    {:noreply, assign(socket, editing_roles: editing_roles)}
  end

  def handle_event("remove_examiner", %{"stage_id" => stage_id, "user_id" => user_id}, socket) do
    stage = Pipeline.get_pipeline_stage!(stage_id)
    Pipeline.remove_examiner(stage, user_id)
    editing_roles = refresh_roles(socket.assigns.editing_roles)
    {:noreply, assign(socket, editing_roles: editing_roles)}
  end

  def handle_event("add_reviewer", %{"stage_id" => stage_id, "user_id" => user_id}, socket) do
    stage = Pipeline.get_pipeline_stage!(stage_id)
    Pipeline.assign_reviewer(stage, user_id)
    editing_roles = refresh_roles(socket.assigns.editing_roles)
    {:noreply, assign(socket, editing_roles: editing_roles)}
  end

  def handle_event("remove_reviewer", %{"stage_id" => stage_id, "user_id" => user_id}, socket) do
    stage = Pipeline.get_pipeline_stage!(stage_id)
    Pipeline.remove_reviewer(stage, user_id)
    editing_roles = refresh_roles(socket.assigns.editing_roles)
    {:noreply, assign(socket, editing_roles: editing_roles)}
  end

  def handle_event("add_advancer", %{"stage_id" => stage_id, "user_id" => user_id}, socket) do
    stage = Pipeline.get_pipeline_stage!(stage_id)
    Pipeline.assign_advancer(stage, user_id)
    editing_roles = refresh_roles(socket.assigns.editing_roles)
    {:noreply, assign(socket, editing_roles: editing_roles)}
  end

  def handle_event("remove_advancer", %{"stage_id" => stage_id, "user_id" => user_id}, socket) do
    stage = Pipeline.get_pipeline_stage!(stage_id)
    Pipeline.remove_advancer(stage, user_id)
    editing_roles = refresh_roles(socket.assigns.editing_roles)
    {:noreply, assign(socket, editing_roles: editing_roles)}
  end

  defp refresh_roles(editing_roles) do
    stage = Pipeline.get_pipeline_stage!(editing_roles.id)

    examiners = Pipeline.list_examiners(stage)
    reviewers = Pipeline.list_reviewers(stage)
    advancers = Pipeline.list_advancers(stage)

    %{stage | examiners: examiners, reviewers: reviewers, advancers: advancers}
  end

  defp reload_stages_with_counts(pipeline_id) do
    Pipeline.list_pipeline_stages(pipeline_id)
    |> Enum.map(fn stage ->
      examiner_count = length(Pipeline.list_examiner_ids(stage))
      reviewer_count = length(Pipeline.list_reviewer_ids(stage))
      advancer_count = length(Pipeline.list_advancer_ids(stage))

      Map.merge(stage, %{
        examiner_count: examiner_count,
        reviewer_count: reviewer_count,
        advancer_count: advancer_count
      })
    end)
  end

  defp available_users(users, assigned) do
    assigned_ids = Enum.map(assigned, & &1.user_id) |> MapSet.new()
    Enum.reject(users, &MapSet.member?(assigned_ids, &1.id))
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

  defp scorecard_template_options(tenant_id) do
    Treby.Scorecards.list_scorecard_templates(tenant_id)
    |> Enum.map(&{&1.name, &1.id})
  end
end
