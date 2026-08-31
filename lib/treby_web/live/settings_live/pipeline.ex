defmodule TrebyWeb.SettingsLive.Pipeline do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Pipeline}
  alias Treby.Pipeline.Pipeline, as: PipelineDef

  def mount(_params, session, socket) do
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

    pipelines = Pipeline.list_pipelines(tenant.id)
    templates = Pipeline.list_templates(tenant.id)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(pipelines: pipelines)
     |> assign(templates: templates)
     |> assign(show_form: false)
     |> assign(show_template_form: false)
     |> assign(form: to_form(Pipeline.change_pipeline(%PipelineDef{})))
     |> assign(template_form: to_form(Pipeline.change_pipeline(%PipelineDef{})))
     |> assign(confirm_delete: nil)}
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
            <p class="mt-1 text-base-content/70">{gettext("Manage your hiring pipelines")}</p>
          </div>
          <.button phx-click="show_create_form" variant="primary">
            + {gettext("New Pipeline")}
          </.button>
        </div>

        <div :if={@show_form} class="mb-8 p-6 bg-base-100 rounded-lg shadow">
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
              <.button type="button" phx-click="cancel_form" variant="ghost">
                {gettext("Cancel")}
              </.button>
            </div>
          </.form>
        </div>

        <div class="space-y-4">
          <div
            :for={pipeline <- @pipelines}
            class="bg-base-100 rounded-lg shadow p-6 flex items-center justify-between"
          >
            <div class="flex items-center gap-4">
              <div class="flex-shrink-0">
                <.icon name="hero-cog-6-tooth" class="h-8 w-8 text-base-content/40" />
              </div>
              <div>
                <div class="flex items-center gap-2">
                  <h3 class="text-lg font-semibold text-base-content">{pipeline.name}</h3>
                  <span
                    :if={pipeline.is_default}
                    class="inline-flex items-center rounded-md bg-blue-50 dark:bg-blue-950 px-2 py-1 text-xs font-medium text-blue-700 dark:text-blue-100 ring-1 ring-inset ring-blue-700/10"
                  >
                    {gettext("Default")}
                  </span>
                </div>
                <p class="text-sm text-base-content/50">
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
                class="text-base-content/70 hover:text-base-content text-sm"
              >
                {gettext("Set Default")}
              </button>
              <button
                phx-click="duplicate_pipeline"
                phx-value-pipeline_id={pipeline.id}
                class="text-base-content/70 hover:text-base-content text-sm"
              >
                {gettext("Duplicate")}
              </button>
              <button
                :if={not pipeline.is_default}
                phx-click="confirm_delete"
                phx-value-id={pipeline.id}
                phx-value-title={gettext("Delete pipeline")}
                phx-value-message={
                  gettext(
                    "Are you sure you want to delete this pipeline? Candidates will be reassigned to the default pipeline."
                  )
                }
                class="text-red-600 hover:text-red-900 text-sm"
              >
                {gettext("Delete")}
              </button>
            </div>
          </div>
        </div>

        <%!-- Templates Section --%>
        <div class="mt-12">
          <div class="flex justify-between items-center mb-6">
            <div>
              <h2 class="text-xl font-bold">{gettext("Pipeline Templates")}</h2>
              <p class="mt-1 text-base-content/70">{gettext("Reusable pipeline configurations")}</p>
            </div>
            <.button phx-click="show_create_template_form" variant="primary">
              + {gettext("New Template")}
            </.button>
          </div>

          <div :if={@show_template_form} class="mb-6 p-6 bg-base-100 rounded-lg shadow">
            <h3 class="text-lg font-semibold mb-4">{gettext("New Template")}</h3>
            <.form
              for={@template_form}
              id="template-form"
              phx-submit="save_template"
              class="flex gap-4 items-end"
            >
              <.input
                field={@template_form[:name]}
                type="text"
                label={gettext("Name")}
                placeholder={gettext("e.g. Standard Engineering Template")}
              />
              <div class="flex gap-2">
                <.button type="submit">{gettext("Create")}</.button>
                <.button type="button" phx-click="cancel_template_form" variant="ghost">
                  {gettext("Cancel")}
                </.button>
              </div>
            </.form>
          </div>

          <div :if={@templates == []} class="text-center py-8 bg-base-100 rounded-lg border">
            <p class="text-base-content/50">{gettext("No templates yet")}</p>
          </div>

          <div class="space-y-3">
            <div
              :for={template <- @templates}
              class="bg-base-100 rounded-lg shadow p-4 flex items-center justify-between"
            >
              <div>
                <h3 class="font-medium text-base-content">{template.name}</h3>
                <p class="text-sm text-base-content/50">
                  {gettext("%{count} stages", count: length(template.pipeline_stages))}
                </p>
              </div>
              <div class="flex items-center gap-2">
                <button
                  phx-click="delete_template"
                  phx-value-id={template.id}
                  data-confirm={gettext("Are you sure you want to delete this template?")}
                  class="text-red-600 hover:text-red-900 text-sm"
                >
                  {gettext("Delete")}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    <.confirm_dialog
      id="confirm-pipeline"
      show={@confirm_delete != nil}
      title={@confirm_delete && @confirm_delete.title}
      message={@confirm_delete && @confirm_delete.message}
      confirm_label="Delete"
      confirm_variant="danger"
      on_confirm="do_delete_pipeline"
      on_cancel="cancel_delete"
      extra_attrs={(@confirm_delete && %{id: @confirm_delete.id}) || %{}}
    />
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
        if socket.assigns.pipelines == [] do
          Pipeline.set_default_pipeline(pipeline)
        end

        pipelines = Pipeline.list_pipelines(socket.assigns.current_tenant.id)

        {:noreply,
         socket
         |> assign(pipelines: pipelines, show_form: false)
         |> put_flash(:info, gettext("Pipeline created"))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(form: to_form(changeset))
         |> put_flash(:error, gettext("Please review the errors below"))}
    end
  end

  def handle_event("set_default", %{"pipeline_id" => pipeline_id}, socket) do
    pipeline = Pipeline.get_pipeline!(pipeline_id)
    Pipeline.set_default_pipeline(pipeline)
    pipelines = Pipeline.list_pipelines(socket.assigns.current_tenant.id)

    {:noreply,
     socket
     |> assign(pipelines: pipelines)
     |> put_flash(:info, gettext("Default pipeline updated"))}
  end

  def handle_event("duplicate_pipeline", %{"pipeline_id" => pipeline_id}, socket) do
    source = Pipeline.get_pipeline!(pipeline_id)
    Pipeline.duplicate_pipeline(source)
    pipelines = Pipeline.list_pipelines(socket.assigns.current_tenant.id)

    {:noreply,
     socket
     |> assign(pipelines: pipelines)
     |> put_flash(:info, gettext("Pipeline duplicated"))}
  end

  def handle_event(
        "confirm_delete",
        %{"id" => id, "title" => title, "message" => message},
        socket
      ) do
    {:noreply, assign(socket, confirm_delete: %{id: id, title: title, message: message})}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, confirm_delete: nil)}
  end

  def handle_event("do_delete_pipeline", %{"id" => pipeline_id}, socket) do
    pipeline = Pipeline.get_pipeline!(pipeline_id)

    case Pipeline.delete_pipeline_with_reassignment(pipeline) do
      :ok ->
        pipelines = Pipeline.list_pipelines(socket.assigns.current_tenant.id)

        {:noreply,
         socket
         |> assign(pipelines: pipelines, confirm_delete: nil)
         |> put_flash(:info, gettext("Pipeline deleted"))}

      {:error, :cannot_delete_default} ->
        {:noreply,
         socket
         |> assign(confirm_delete: nil)
         |> put_flash(:error, gettext("Cannot delete the default pipeline"))}
    end
  end

  def handle_event("show_create_template_form", _, socket) do
    form = to_form(Pipeline.change_pipeline(%PipelineDef{}))
    {:noreply, assign(socket, show_template_form: true, template_form: form)}
  end

  def handle_event("cancel_template_form", _, socket) do
    {:noreply, assign(socket, show_template_form: false)}
  end

  def handle_event("save_template", %{"pipeline" => params}, socket) do
    attrs =
      params
      |> Map.put("tenant_id", socket.assigns.current_tenant.id)
      |> Map.put("is_template", true)

    case Pipeline.create_template(attrs) do
      {:ok, _template} ->
        templates = Pipeline.list_templates(socket.assigns.current_tenant.id)

        {:noreply,
         socket
         |> assign(templates: templates, show_template_form: false)
         |> put_flash(:info, gettext("Template created"))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(template_form: to_form(changeset))
         |> put_flash(:error, gettext("Please review the errors below"))}
    end
  end

  def handle_event("delete_template", %{"id" => template_id}, socket) do
    template = Pipeline.get_pipeline!(template_id)

    case Pipeline.delete_template(template) do
      :ok ->
        templates = Pipeline.list_templates(socket.assigns.current_tenant.id)

        {:noreply,
         socket
         |> assign(templates: templates)
         |> put_flash(:info, gettext("Template deleted"))}

      {:error, reason} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           gettext("Could not delete template: %{reason}", reason: inspect(reason))
         )}
    end
  end
end
