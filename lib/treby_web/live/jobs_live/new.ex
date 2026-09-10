defmodule TrebyWeb.JobsLive.New do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Jobs, Customization, Pipeline}
  alias Treby.Jobs.Job

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    {user, tenant} = resolve_user_tenant(socket, session)
    {pipelines, default_pipeline_id, job_fields} = load_tenant_resources(tenant)

    initial_job = %Job{
      status: "open",
      visible: true,
      pipeline_id: default_pipeline_id,
      tenant_id: tenant && tenant.id
    }

    changeset = Jobs.change_job(initial_job)
    form = to_form(changeset)
    preview_job = build_preview_job(changeset, tenant)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(pipelines: pipelines)
     |> assign(default_pipeline_id: default_pipeline_id)
     |> assign(job_fields: job_fields)
     |> assign(form: form)
     |> assign(preview_job: preview_job)
     |> assign(career_page: nil)
     |> refresh_workspace()}
  end

  defp resolve_user_tenant(socket, session) do
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
  end

  defp load_tenant_resources(nil), do: {[], nil, []}

  defp load_tenant_resources(tenant) do
    {
      Pipeline.list_pipelines(tenant.id),
      Pipeline.default_pipeline_id(tenant.id),
      Customization.list_custom_fields_for(tenant.id, "job")
    }
  end

  defp build_preview_job(changeset, tenant) do
    job = Ecto.Changeset.apply_changes(changeset)

    job
    |> Map.put(:inserted_at, job.inserted_at || DateTime.utc_now())
    |> Map.put(:tenant, tenant)
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <.page_header
          title={gettext("New Job")}
          breadcrumbs={[
            %{
              label: gettext("Jobs"),
              href: if(@current_tenant, do: "/#{@current_tenant.slug}/app/jobs", else: "/app/jobs")
            },
            %{label: gettext("New")}
          ]}
        >
          <:actions>
            <.link
              navigate={
                if @current_tenant, do: "/#{@current_tenant.slug}/app/jobs", else: ~p"/app/jobs"
              }
              class="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg text-sm font-medium bg-zinc-50 dark:bg-zinc-800 text-zinc-700 dark:text-zinc-300 hover:bg-zinc-100 dark:hover:bg-zinc-700 border border-zinc-200 dark:border-zinc-700"
            >
              <.icon name="hero-arrow-left" class="w-4 h-4" /> {gettext("Back to Jobs")}
            </.link>
          </:actions>
        </.page_header>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 items-start">
          <%!-- Left: Form --%>
          <div class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm p-6">
            <h2 class="text-base font-semibold text-zinc-900 dark:text-zinc-100 mb-1">
              {gettext("Job details")}
            </h2>
            <p class="text-sm text-zinc-500 dark:text-zinc-400 mb-6">
              {gettext("Fill in the offer details. The preview on the right updates live.")}
            </p>

            <.form for={@form} id="job-create-form" phx-change="validate" phx-submit="save">
              <.input
                field={@form[:title]}
                type="text"
                label={gettext("Title")}
                placeholder="e.g. Senior Elixir Developer"
              />
              <.input
                field={@form[:description]}
                type="textarea"
                label={gettext("Description")}
                rows="8"
              />
              <p class="-mt-2 mb-3 text-xs text-zinc-500 dark:text-zinc-400">
                {gettext("Supports Markdown formatting")}
              </p>

              <.input
                field={@form[:salary_range]}
                type="text"
                label={gettext("Salary Range")}
                placeholder="$100k-$150k"
              />

              <.input
                field={@form[:location]}
                type="text"
                label={gettext("Location")}
                placeholder="e.g. Milan, Remote"
              />

              <.input
                field={@form[:employment_type]}
                type="select"
                label={gettext("Employment Type")}
                options={[
                  {gettext("Full-time"), "full_time"},
                  {gettext("Part-time"), "part_time"},
                  {gettext("Contract"), "contract"},
                  {gettext("Internship"), "internship"}
                ]}
                prompt="—"
              />

              <.input
                field={@form[:workplace_type]}
                type="select"
                label={gettext("Workplace")}
                options={[
                  {gettext("On-site"), "on_site"},
                  {gettext("Hybrid"), "hybrid"},
                  {gettext("Remote"), "remote"}
                ]}
                prompt="—"
              />

              <.input
                field={@form[:pipeline_id]}
                type="select"
                label={gettext("Pipeline")}
                options={Enum.map(@pipelines, &{&1.name, &1.id})}
              />

              <div class="grid grid-cols-2 gap-4 mt-2">
                <.input
                  field={@form[:status]}
                  type="select"
                  label={gettext("Status")}
                  options={[{gettext("Open"), "open"}, {gettext("Closed"), "closed"}]}
                />

                <div>
                  <.input
                    field={@form[:visible]}
                    type="select"
                    label={gettext("Visibility")}
                    options={[{gettext("Public"), "true"}, {gettext("Private"), "false"}]}
                    disabled={to_string(@form[:status].value) == "closed"}
                  />
                  <p
                    :if={to_string(@form[:status].value) == "closed"}
                    class="mt-1 text-xs text-amber-600 dark:text-amber-400"
                  >
                    {gettext("Closed jobs are private and hidden from public boards.")}
                  </p>
                  <p
                    :if={to_string(@form[:status].value) != "closed"}
                    class="mt-1 text-xs text-zinc-500 dark:text-zinc-400"
                  >
                    {gettext(
                      "Public jobs appear on career pages. Private jobs are only reachable via direct link."
                    )}
                  </p>
                </div>
              </div>

              <div
                :if={@job_fields != []}
                class="mt-6 border-t border-zinc-200 dark:border-zinc-700 pt-4"
              >
                <h3 class="text-sm font-medium text-zinc-900 dark:text-zinc-100/80 mb-3">
                  {gettext("Additional Information")}
                </h3>
                <div :for={field <- @job_fields} class="mb-3">
                  <%= cond do %>
                    <% field.field_type == "select" -> %>
                      <.input
                        name={"custom_fields[#{field.id}]"}
                        type="select"
                        label={field.name}
                        options={field.options}
                        prompt="—"
                      />
                    <% field.field_type == "date" -> %>
                      <.input name={"custom_fields[#{field.id}]"} type="date" label={field.name} />
                    <% field.field_type == "number" -> %>
                      <.input name={"custom_fields[#{field.id}]"} type="number" label={field.name} />
                    <% field.field_type == "url" -> %>
                      <.input
                        name={"custom_fields[#{field.id}]"}
                        type="url"
                        label={field.name}
                        placeholder="https://"
                      />
                    <% true -> %>
                      <.input name={"custom_fields[#{field.id}]"} type="text" label={field.name} />
                  <% end %>
                </div>
              </div>

              <div class="mt-6 flex gap-3">
                <.button type="submit" variant="primary" loading_text={gettext("Creating...")}>
                  {gettext("Create job")}
                </.button>
                <.link
                  navigate={
                    if @current_tenant, do: "/#{@current_tenant.slug}/app/jobs", else: ~p"/app/jobs"
                  }
                  class="inline-flex items-center justify-center px-4 py-2 rounded-lg text-sm font-medium bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 text-zinc-700 dark:text-zinc-300 hover:bg-zinc-50 dark:hover:bg-zinc-700"
                >
                  {gettext("Cancel")}
                </.link>
              </div>
            </.form>
          </div>

          <%!-- Right: Live Preview --%>
          <div class="lg:sticky lg:top-6">
            <h2 class="text-sm font-semibold text-zinc-900 dark:text-zinc-100 mb-3 flex items-center gap-2">
              <.icon name="hero-eye" class="w-4 h-4 text-zinc-500 dark:text-zinc-400" />
              {gettext("Public preview")}
              <span class="ml-auto text-xs font-normal text-zinc-500 dark:text-zinc-400">
                {gettext("As candidates will see it")}
              </span>
            </h2>

            <div
              id="job-preview-card"
              class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm overflow-hidden"
            >
              <div class="bg-zinc-50 dark:bg-zinc-800 border-b border-zinc-200 dark:border-zinc-700 px-5 py-2 flex items-center gap-2">
                <span class="w-2 h-2 rounded-full bg-red-400"></span>
                <span class="w-2 h-2 rounded-full bg-yellow-400"></span>
                <span class="w-2 h-2 rounded-full bg-green-400"></span>
                <span class="ml-3 text-xs text-zinc-500 dark:text-zinc-400 truncate">
                  {if @current_tenant,
                    do: "#{@current_tenant.slug}/careers/preview",
                    else: "careers/preview"}
                </span>
                <.badge
                  :if={@preview_job.status == "closed"}
                  variant="default"
                  class="ml-auto text-[10px] uppercase"
                >
                  {gettext("Closed")}
                </.badge>
                <.badge
                  :if={@preview_job.status != "closed" and @preview_job.visible == false}
                  variant="warning"
                  class="ml-auto text-[10px]"
                >
                  {gettext("Private")}
                </.badge>
                <.badge
                  :if={@preview_job.status == "open" and @preview_job.visible != false}
                  variant="success"
                  class="ml-auto text-[10px]"
                >
                  {gettext("Public")}
                </.badge>
              </div>

              <div class="p-6">
                <div
                  :if={@preview_job.status != "open"}
                  class="mb-4 rounded-lg bg-amber-50 dark:bg-amber-950 border border-amber-200 dark:border-amber-800 px-4 py-3 text-sm text-amber-800 dark:text-amber-200"
                >
                  {gettext("This position is closed and will be hidden from public career pages.")}
                </div>
                <div
                  :if={@preview_job.status == "open" and @preview_job.visible == false}
                  class="mb-4 rounded-lg bg-zinc-50 dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 px-4 py-3 text-sm text-zinc-600 dark:text-zinc-300"
                >
                  {gettext("Private — only reachable via direct link, not listed on career pages.")}
                </div>

                <div :if={@current_tenant} class="mb-4">
                  <h3 class="text-sm font-semibold text-zinc-900 dark:text-zinc-100">
                    {@current_tenant.name}
                  </h3>
                  <p class="text-xs text-zinc-500 dark:text-zinc-400">
                    {gettext("Company • via Treby career page")}
                  </p>
                </div>

                <h1 class="text-2xl font-bold text-zinc-900 dark:text-zinc-100">
                  {if @preview_job.title not in [nil, ""],
                    do: @preview_job.title,
                    else: gettext("Job title preview")}
                </h1>

                <div class="mt-3 flex flex-wrap items-center gap-3 text-sm text-zinc-600 dark:text-zinc-400">
                  <span
                    :if={@preview_job.salary_range not in [nil, ""]}
                    class="inline-flex items-center gap-1"
                  >
                    <.icon name="hero-banknotes" class="w-4 h-4" /> {@preview_job.salary_range}
                  </span>
                  <span
                    :if={@preview_job.location not in [nil, ""]}
                    class="inline-flex items-center gap-1"
                  >
                    <.icon name="hero-map-pin" class="w-4 h-4" /> {@preview_job.location}
                  </span>
                  <.badge :if={@preview_job.employment_type not in [nil, ""]} variant="default">
                    {Treby.Jobs.Job.employment_type_label(@preview_job.employment_type)}
                  </.badge>
                  <.badge :if={@preview_job.workplace_type not in [nil, ""]} variant="default">
                    {Treby.Jobs.Job.workplace_type_label(@preview_job.workplace_type)}
                  </.badge>
                  <span class="inline-flex items-center gap-1">
                    <.icon name="hero-calendar" class="w-4 h-4" />
                    {Calendar.strftime(@preview_job.inserted_at || DateTime.utc_now(), "%b %d, %Y")}
                  </span>
                </div>

                <div class="mt-6">
                  <.markdown
                    :if={@preview_job.description not in [nil, ""]}
                    text={@preview_job.description}
                  />
                  <p
                    :if={@preview_job.description in [nil, ""]}
                    class="text-sm text-zinc-500 dark:text-zinc-400 italic"
                  >
                    {gettext("Job description will appear here. Supports Markdown.")}
                  </p>
                </div>

                <button
                  type="button"
                  disabled={@preview_job.status != "open"}
                  class={[
                    "mt-8 inline-flex items-center justify-center rounded-lg px-5 py-2.5 text-sm font-medium transition-colors",
                    @preview_job.status == "open" &&
                      "bg-orange-600 hover:bg-orange-700 text-white shadow-sm",
                    @preview_job.status != "open" &&
                      "bg-zinc-100 dark:bg-zinc-700 text-zinc-400 dark:text-zinc-500 cursor-not-allowed"
                  ]}
                >
                  {if @preview_job.status == "open",
                    do: gettext("Apply Now"),
                    else: gettext("Position closed")}
                </button>
              </div>
            </div>

            <p class="mt-3 text-xs text-zinc-500 dark:text-zinc-400 text-center">
              {gettext("Preview updates as you type. Markdown is rendered as on the public page.")}
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("validate", params, socket) do
    job_params = Map.get(params, "job", %{})
    tenant = socket.assigns.current_tenant

    initial = %Job{
      status: "open",
      visible: true,
      pipeline_id: socket.assigns.default_pipeline_id,
      tenant_id: tenant && tenant.id
    }

    changeset = Jobs.change_job(initial, job_params)
    # Don't mark as used_input? to show errors immediately we set action :validate
    changeset = Map.put(changeset, :action, :validate)

    preview_job = build_preview_job(changeset, tenant)

    {:noreply,
     socket
     |> assign(form: to_form(changeset))
     |> assign(preview_job: preview_job)}
  end

  def handle_event("save", params, socket) do
    job_params = Map.get(params, "job", %{})
    custom_fields_values = Map.get(params, "custom_fields", %{})
    tenant = socket.assigns.current_tenant

    pipeline_id =
      case Map.get(job_params, "pipeline_id") do
        id when id not in [nil, ""] -> id
        _ -> Pipeline.default_pipeline_id(tenant.id)
      end

    # Coerce visible to false when status is closed
    job_params =
      if Map.get(job_params, "status") == "closed" do
        Map.put(job_params, "visible", false)
      else
        job_params
      end

    attrs =
      job_params
      |> Map.put("pipeline_id", pipeline_id)
      |> Map.put("tenant_id", tenant.id)

    required_fields =
      Customization.list_custom_fields_for(tenant.id, "job")
      |> Enum.filter(& &1.required)
      |> Enum.filter(fn field ->
        value = Map.get(custom_fields_values, to_string(field.id), "")
        value == "" or is_nil(value)
      end)

    if required_fields != [] do
      missing = Enum.map_join(required_fields, ", ", & &1.name)

      {:noreply,
       socket
       |> put_flash(:error, gettext("Please fill in required fields: %{fields}", fields: missing))}
    else
      attrs = Map.put(attrs, "custom_fields", custom_fields_values)

      case Jobs.create_job(attrs) do
        {:ok, job} ->
          {:noreply,
           socket
           |> put_flash(:info, gettext("Job created successfully"))
           |> push_navigate(to: ~p"/app/jobs/#{job.id}")}

        {:error, changeset} ->
          # Keep preview in sync even on error
          preview_job = build_preview_job(changeset, tenant)

          {:noreply,
           socket
           |> assign(form: to_form(changeset))
           |> assign(preview_job: preview_job)
           |> put_flash(:error, gettext("Please review the errors below"))}
      end
    end
  end

  defp refresh_workspace(socket) do
    case socket.assigns[:current_tenant] do
      nil ->
        socket

      tenant ->
        memberships = Treby.Memberships.list_tenants_for_user(socket.assigns.current_user.id)
        current_membership = Enum.find(memberships, &(&1.tenant.id == tenant.id))

        socket
        |> assign(available_tenants: memberships)
        |> assign(current_membership: current_membership)
    end
  end
end
