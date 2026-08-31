defmodule TrebyWeb.ImportLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Jobs, Sources, CsvImport}
  alias Treby.Pipeline

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

    jobs = Jobs.list_jobs(tenant.id)
    sources = Sources.list_sources(tenant.id)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(jobs: jobs, sources: sources)
     |> assign(step: 1)
     |> assign(upload_errors: [])
     |> assign(rows: [])
     |> assign(headers: [])
     |> assign(mapping: %{})
     |> assign(preview: [])
     |> assign(selected_job_id: nil)
     |> assign(selected_stage_id: nil)
     |> assign(selected_source: nil)
     |> assign(import_form: to_form(%{}))
     |> assign(import_results: nil)
     |> assign(import_log: nil)
     |> allow_upload(:csv,
       accept: [".csv", "text/csv"],
       max_entries: 1,
       max_file_size: 10_000_000
     )}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8 max-w-4xl mx-auto">
        <.page_header
          title={gettext("Import Candidates")}
          subtitle={gettext("Upload a CSV file to bulk import candidates")}
          breadcrumbs={[
            %{label: gettext("Candidates"), href: ~p"/app/candidates"},
            %{label: gettext("Import")}
          ]}
        />

        <div class="mt-6 flex items-center gap-2 text-sm text-base-content/70">
          <span class={[
            "px-3 py-1 rounded-full",
            @step >= 1 && "bg-blue-100 text-blue-800",
            @step < 1 && "bg-base-200 text-base-content/50"
          ]}>
            1. {gettext("Upload")}
          </span>
          <span class="text-base-content/30">→</span>
          <span class={[
            "px-3 py-1 rounded-full",
            @step >= 2 && "bg-blue-100 text-blue-800",
            @step < 2 && "bg-base-200 text-base-content/50"
          ]}>
            2. {gettext("Map")}
          </span>
          <span class="text-base-content/30">→</span>
          <span class={[
            "px-3 py-1 rounded-full",
            @step >= 3 && "bg-blue-100 text-blue-800",
            @step < 3 && "bg-base-200 text-base-content/50"
          ]}>
            3. {gettext("Preview")}
          </span>
          <span class="text-base-content/30">→</span>
          <span class={[
            "px-3 py-1 rounded-full",
            @step >= 4 && "bg-blue-100 text-blue-800",
            @step < 4 && "bg-base-200 text-base-content/50"
          ]}>
            4. {gettext("Import")}
          </span>
        </div>

        <.card :if={@step == 1} class="shadow mt-8">
          <div
            class="border-2 border-dashed border-base-300 rounded-lg p-12 text-center hover:border-blue-400 transition-colors bg-base-200"
            phx-drop-target={@uploads.csv.ref}
          >
            <.icon name="hero-document-arrow-up" class="w-12 h-12 text-base-content/40 mx-auto" />
            <p class="mt-4 text-base-content/70">{gettext("Drop a CSV file here or")}</p>
            <.live_file_input
              upload={@uploads.csv}
              class="mt-2 text-blue-600 underline cursor-pointer"
            />
            <p class="mt-2 text-xs text-base-content/50">{gettext("Max 10MB, CSV format")}</p>
          </div>

          <div :for={err <- upload_errors(@uploads.csv)} class="mt-4 text-red-600 text-sm">
            {upload_error_to_string(err)}
          </div>

          <div :if={@uploads.csv.entries != []} class="mt-6">
            <.button variant="primary" phx-click="process_upload">
              {gettext("Continue")}
            </.button>
          </div>
          <.empty_state
            :if={@uploads.csv.entries == []}
            icon="hero-arrow-up-tray"
            title={gettext("No file selected")}
            description={gettext("Select a CSV file with candidate data to get started.")}
            class="py-8"
          />
        </.card>

        <.card :if={@step == 2} class="shadow mt-8">
          <h2 class="text-lg font-semibold">{gettext("Map Columns")}</h2>
          <p class="mt-1 text-sm text-base-content/70">
            {gettext("Match CSV columns to candidate fields")}
          </p>

          <div class="mt-6 space-y-4">
            <div :for={csv_header <- @headers} class="flex items-center gap-4">
              <span class="w-48 text-sm font-mono bg-base-200 px-2 py-1 rounded">{csv_header}</span>
              <span class="text-base-content/40">→</span>
              <select
                phx-change="update_mapping"
                phx-value-header={csv_header}
                class="select flex-1"
              >
                <option value="">{gettext("Skip this column")}</option>
                <option
                  :if={Map.get(@mapping, csv_header) == "name"}
                  value="name"
                  selected
                >
                  {gettext("Name")}
                </option>
                <option :if={Map.get(@mapping, csv_header) != "name"} value="name">
                  {gettext("Name")}
                </option>
                <option
                  :if={Map.get(@mapping, csv_header) == "email"}
                  value="email"
                  selected
                >
                  {gettext("Email")}
                </option>
                <option :if={Map.get(@mapping, csv_header) != "email"} value="email">
                  {gettext("Email")}
                </option>
                <option
                  :if={Map.get(@mapping, csv_header) == "phone"}
                  value="phone"
                  selected
                >
                  {gettext("Phone")}
                </option>
                <option :if={Map.get(@mapping, csv_header) != "phone"} value="phone">
                  {gettext("Phone")}
                </option>
                <option
                  :if={Map.get(@mapping, csv_header) == "linkedin_url"}
                  value="linkedin_url"
                  selected
                >
                  {gettext("LinkedIn")}
                </option>
                <option :if={Map.get(@mapping, csv_header) != "linkedin_url"} value="linkedin_url">
                  {gettext("LinkedIn")}
                </option>
              </select>
            </div>
          </div>

          <div class="mt-8 flex gap-4">
            <.button variant="ghost" phx-click="go_to_step_1">
              {gettext("Back")}
            </.button>
            <.button variant="primary" phx-click="go_to_preview">
              {gettext("Preview")}
            </.button>
          </div>
        </.card>

        <.card :if={@step == 3} class="shadow mt-8">
          <h2 class="text-lg font-semibold">{gettext("Preview")}</h2>
          <p class="mt-1 text-sm text-base-content/70">
            {gettext("Review first 10 rows before importing")}
          </p>

          <div class="mt-6 overflow-x-auto">
            <table class="w-full text-sm border">
              <thead class="bg-base-200">
                <tr>
                  <th class="px-3 py-2 text-left border">{gettext("Status")}</th>
                  <th
                    :for={{_header, field} <- @mapping}
                    class="px-3 py-2 text-left border"
                  >
                    {field}
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr
                  :for={row <- @preview}
                  class={[
                    "border",
                    row.is_duplicate && "bg-yellow-50 dark:bg-yellow-950"
                  ]}
                >
                  <td class="px-3 py-2 border">
                    <.badge :if={row.is_duplicate} variant="warning">{gettext("Duplicate")}</.badge>
                    <.badge :if={match?({:error, _}, row.validation)} variant="danger">
                      {gettext("Error")}
                    </.badge>
                    <.badge
                      :if={row.validation == :ok and not row.is_duplicate}
                      variant="success"
                    >
                      {gettext("New")}
                    </.badge>
                  </td>
                  <td
                    :for={{_header, field} <- @mapping}
                    class="px-3 py-2 border text-base-content/80"
                  >
                    {Map.get(row.candidate_attrs, field, "")}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <.card :if={@jobs != []} class="mt-8 bg-base-200 border-0 shadow-none">
            <h3 class="font-medium">{gettext("Add to Job (Optional)")}</h3>
            <.form for={@import_form} id="import-options-form">
              <div class="mt-4 grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm text-base-content/70">{gettext("Job")}</label>
                  <select phx-change="select_job" class="select w-full mt-1">
                    <option value="">{gettext("None")}</option>
                    <option :for={job <- @jobs} value={job.id}>{job.title}</option>
                  </select>
                </div>

                <div :if={@selected_job_id} class="space-y-3">
                  <label class="block text-sm text-base-content/70">{gettext("Stage")}</label>
                  <select phx-change="select_stage" class="select w-full mt-1">
                    <option value="">{gettext("First stage")}</option>
                    <option :for={stage <- get_stages_for_job(@selected_job_id)} value={stage.id}>
                      {stage.name}
                    </option>
                  </select>
                </div>
              </div>

              <div class="mt-4">
                <label class="block text-sm text-base-content/70">{gettext("Source")}</label>
                <select phx-change="select_source" class="select w-full mt-1">
                  <option value="">{gettext("None")}</option>
                  <option :for={source <- @sources} value={source.name}>{source.name}</option>
                </select>
              </div>
            </.form>
          </.card>

          <div class="mt-8 flex gap-4">
            <.button variant="ghost" phx-click="go_to_step_2">
              {gettext("Back")}
            </.button>
            <.button variant="primary" phx-click="execute_import">
              {gettext("Import %{count} candidates", count: length(@rows))}
            </.button>
          </div>
        </.card>

        <.card :if={@step == 4 and @import_results} class="shadow mt-8">
          <h2 class="text-lg font-semibold">{gettext("Import Complete")}</h2>

          <div class="mt-6 bg-green-50 dark:bg-green-950 border border-green-200 dark:border-green-900 rounded-lg p-6">
            <div class="grid grid-cols-3 gap-4 text-center">
              <div>
                <div class="text-2xl font-bold text-green-600">{@import_results.imported}</div>
                <.badge variant="success" class="mt-1">{gettext("Imported")}</.badge>
              </div>
              <div>
                <div class="text-2xl font-bold text-yellow-600">{@import_results.skipped}</div>
                <.badge variant="warning" class="mt-1">{gettext("Skipped")}</.badge>
              </div>
              <div>
                <div class="text-2xl font-bold text-red-600">{length(@import_results.errors)}</div>
                <.badge variant="danger" class="mt-1">{gettext("Errors")}</.badge>
              </div>
            </div>
          </div>

          <div :if={@import_results.errors != []} class="mt-6">
            <h3 class="font-medium text-red-600">{gettext("Errors")}</h3>
            <div
              :for={error <- @import_results.errors}
              class="mt-2 text-sm bg-red-50 dark:bg-red-950 rounded p-3"
            >
              <span class="font-mono">{inspect(error)}</span>
            </div>
          </div>

          <div class="mt-8 flex gap-4">
            <.button variant="primary" navigate={~p"/app/import"}>
              {gettext("Import More")}
            </.button>
            <.button variant="ghost" navigate={~p"/app/candidates"}>
              {gettext("View Candidates")}
            </.button>
          </div>
        </.card>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("validate_upload", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("process_upload", _params, socket) do
    [{_ref, _entry}] = socket.assigns.uploads.csv.entries

    {:noreply,
     consume_uploaded_entries(socket, :csv, fn meta, _entry ->
       csv_content = File.read!(meta.path)

       case CsvImport.parse_csv(csv_content) do
         {:ok, %{rows: rows, headers: headers}} ->
           {:ok, mapping} = CsvImport.auto_detect_mapping(headers)

           socket
           |> assign(step: 2, rows: rows, headers: headers, mapping: mapping)

         {:error, reason} ->
           put_flash(socket, :error, reason)
       end
     end)}
  end

  def handle_event("update_mapping", %{"header" => header, "value" => value}, socket) do
    mapping =
      if value == "" do
        Map.delete(socket.assigns.mapping, header)
      else
        Map.put(socket.assigns.mapping, header, value)
      end

    {:noreply, assign(socket, mapping: mapping)}
  end

  def handle_event("go_to_step_1", _, socket) do
    {:noreply, assign(socket, step: 1)}
  end

  def handle_event("go_to_step_2", _, socket) do
    {:noreply, assign(socket, step: 2)}
  end

  def handle_event("go_to_preview", _, socket) do
    %{rows: rows, mapping: mapping} = socket.assigns

    {:ok, preview} = CsvImport.preview_import(rows, mapping, socket.assigns.current_tenant.id)

    {:noreply,
     socket
     |> assign(step: 3, preview: preview)}
  end

  def handle_event("select_job", %{"job_id" => job_id}, socket) do
    job_id = if job_id == "", do: nil, else: job_id
    {:noreply, assign(socket, selected_job_id: job_id)}
  end

  def handle_event("select_stage", %{"stage_id" => stage_id}, socket) do
    stage_id = if stage_id == "", do: nil, else: stage_id
    {:noreply, assign(socket, selected_stage_id: stage_id)}
  end

  def handle_event("select_source", %{"source" => source}, socket) do
    source = if source == "", do: nil, else: source
    {:noreply, assign(socket, selected_source: source)}
  end

  def handle_event("execute_import", _params, socket) do
    %{rows: rows, mapping: mapping} = socket.assigns
    tenant_id = socket.assigns.current_tenant.id

    # Get the first pipeline stage if no job selected
    pipeline_stage_id =
      socket.assigns.selected_stage_id ||
        if job_id = socket.assigns.selected_job_id do
          case Pipeline.list_pipeline_stages_for_job(job_id) do
            [first | _] -> first.id
            [] -> nil
          end
        else
          case Pipeline.list_pipeline_stages(Pipeline.default_pipeline_id(tenant_id)) do
            [first | _] -> first.id
            [] -> nil
          end
        end

    {:ok, results} =
      CsvImport.execute_import(rows, mapping, tenant_id,
        job_id: socket.assigns.selected_job_id,
        pipeline_stage_id: pipeline_stage_id,
        source: socket.assigns.selected_source
      )

    # Log the import
    {:ok, log} =
      CsvImport.log_import("import.csv", tenant_id, results)

    {:noreply,
     socket
     |> assign(step: 4, import_results: results, import_log: log)
     |> put_flash(:info, gettext("Import complete"))}
  end

  defp upload_error_to_string(:too_large), do: gettext("File is too large (max 10MB)")

  defp upload_error_to_string(:not_accepted),
    do: gettext("Invalid file type. Please upload a CSV file")

  defp upload_error_to_string(:too_many_files), do: gettext("Only one file allowed")
  defp upload_error_to_string(err), do: gettext("Upload error: %{err}", err: inspect(err))

  defp get_stages_for_job(job_id) do
    job_id
    |> Pipeline.list_pipeline_stages_for_job()
    |> Enum.sort_by(& &1.position)
  end
end
