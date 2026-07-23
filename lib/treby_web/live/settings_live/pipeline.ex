defmodule TrebyWeb.SettingsLive.Pipeline do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Pipeline}
  alias Treby.Pipeline.Pipeline, as: PipelineDef

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])
    pipelines = Pipeline.list_pipelines(tenant.id)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(pipelines: pipelines)
     |> assign(show_form: false)
     |> assign(form: to_form(Pipeline.change_pipeline(%PipelineDef{})))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <div class="flex justify-between items-center mb-8">
          <div>
            <.link navigate={~p"/app/settings"} class="text-blue-600 hover:text-blue-900 text-sm">
              &larr; {gettext("Settings")}
            </.link>
            <h1 class="text-2xl font-bold mt-2">{gettext("Pipelines")}</h1>
            <p class="mt-1 text-gray-600">{gettext("Manage your hiring pipelines")}</p>
          </div>
          <button
            phx-click="show_create_form"
            class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
          >
            + {gettext("New Pipeline")}
          </button>
        </div>

        <div :if={@show_form} class="mb-8 p-6 bg-white rounded-lg shadow">
          <h2 class="text-lg font-semibold mb-4">{gettext("New Pipeline")}</h2>
          <.form
            for={@form}
            id="pipeline-form"
            phx-submit="save_pipeline"
            class="flex gap-4 items-end"
          >
            <.input
              field={@form[:name]}
              type="text"
              label={gettext("Name")}
              placeholder={gettext("e.g. Engineering Pipeline")}
            />
            <div class="flex gap-2">
              <.button type="submit">{gettext("Create")}</.button>
              <.button type="button" phx-click="cancel_form" class="bg-gray-500">
                {gettext("Cancel")}
              </.button>
            </div>
          </.form>
        </div>

        <div class="space-y-4">
          <div
            :for={pipeline <- @pipelines}
            class="bg-white rounded-lg shadow p-6 flex items-center justify-between"
          >
            <div class="flex items-center gap-4">
              <div class="flex-shrink-0">
                <.icon name="hero-cog-6-tooth" class="h-8 w-8 text-gray-400" />
              </div>
              <div>
                <div class="flex items-center gap-2">
                  <h3 class="text-lg font-semibold text-gray-900">{pipeline.name}</h3>
                  <span
                    :if={pipeline.is_default}
                    class="inline-flex items-center rounded-md bg-blue-50 px-2 py-1 text-xs font-medium text-blue-700 ring-1 ring-inset ring-blue-700/10"
                  >
                    {gettext("Default")}
                  </span>
                </div>
                <p class="text-sm text-gray-500">
                  {gettext("%{count} stages", count: length(pipeline.pipeline_stages))} &middot; {gettext(
                    "%{count} active jobs",
                    count: Pipeline.count_active_jobs(pipeline.id)
                  )}
                </p>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <.link
                navigate={~p"/app/settings/pipeline/#{pipeline.id}"}
                class="text-blue-600 hover:text-blue-900 text-sm font-medium"
              >
                {gettext("Edit")}
              </.link>
              <button
                :if={not pipeline.is_default}
                phx-click="set_default"
                phx-value-pipeline_id={pipeline.id}
                class="text-gray-600 hover:text-gray-900 text-sm"
              >
                {gettext("Set Default")}
              </button>
              <button
                phx-click="duplicate_pipeline"
                phx-value-pipeline_id={pipeline.id}
                class="text-gray-600 hover:text-gray-900 text-sm"
              >
                {gettext("Duplicate")}
              </button>
              <button
                :if={not pipeline.is_default}
                phx-click="delete_pipeline"
                phx-value-pipeline_id={pipeline.id}
                class="text-red-600 hover:text-red-900 text-sm"
              >
                {gettext("Delete")}
              </button>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("show_create_form", _, socket) do
    form = to_form(Pipeline.change_pipeline(%PipelineDef{}))
    {:noreply, assign(socket, show_form: true, form: form)}
  end

  def handle_event("cancel_form", _, socket) do
    {:noreply, assign(socket, show_form: false)}
  end

  def handle_event("save_pipeline", %{"pipeline" => params}, socket) do
    attrs = Map.put(params, "tenant_id", socket.assigns.current_tenant.id)

    case Pipeline.create_pipeline(attrs) do
      {:ok, pipeline} ->
        # If this is the first pipeline, make it default
        if length(socket.assigns.pipelines) == 0 do
          Pipeline.set_default_pipeline(pipeline)
        end

        pipelines = Pipeline.list_pipelines(socket.assigns.current_tenant.id)

        {:noreply,
         socket
         |> assign(pipelines: pipelines, show_form: false)
         |> put_flash(:info, "Pipeline created")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("set_default", %{"pipeline_id" => pipeline_id}, socket) do
    pipeline = Pipeline.get_pipeline!(pipeline_id)
    Pipeline.set_default_pipeline(pipeline)
    pipelines = Pipeline.list_pipelines(socket.assigns.current_tenant.id)

    {:noreply,
     socket
     |> assign(pipelines: pipelines)
     |> put_flash(:info, "Default pipeline updated")}
  end

  def handle_event("duplicate_pipeline", %{"pipeline_id" => pipeline_id}, socket) do
    source = Pipeline.get_pipeline!(pipeline_id)
    Pipeline.duplicate_pipeline(source)
    pipelines = Pipeline.list_pipelines(socket.assigns.current_tenant.id)

    {:noreply,
     socket
     |> assign(pipelines: pipelines)
     |> put_flash(:info, "Pipeline duplicated")}
  end

  def handle_event("delete_pipeline", %{"pipeline_id" => pipeline_id}, socket) do
    pipeline = Pipeline.get_pipeline!(pipeline_id)

    case Pipeline.delete_pipeline_with_reassignment(pipeline) do
      :ok ->
        pipelines = Pipeline.list_pipelines(socket.assigns.current_tenant.id)

        {:noreply,
         socket
         |> assign(pipelines: pipelines)
         |> put_flash(:info, "Pipeline deleted")}

      {:error, :cannot_delete_default} ->
        {:noreply, put_flash(socket, :error, "Cannot delete the default pipeline")}
    end
  end
end
