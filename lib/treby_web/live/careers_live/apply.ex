defmodule TrebyWeb.CareersLive.Apply do
  use TrebyWeb, :live_view

  alias Treby.{
    Tenants,
    Jobs,
    Candidates,
    Pipeline,
    Careers,
    Customization,
    Sources,
    CandidatePortal
  }

  def mount(%{"tenant_slug" => tenant_slug, "job_id" => job_id}, session, socket) do
    socket = set_locale_from_session(socket, session)
    tenant = Tenants.get_tenant_by_slug!(tenant_slug)

    case Jobs.get_job(tenant.id, job_id) do
      nil ->
        {:ok, redirect(socket, to: ~p"/404")}

      job ->
        career_page = Careers.get_published_career_page_by_tenant(tenant.id)
        pipeline_id = Pipeline.default_pipeline_id(tenant.id)
        stages = Pipeline.list_pipeline_stages(pipeline_id)
        first_stage = List.first(stages)
        application_fields = Customization.list_custom_fields_for(tenant.id, "application")
        sources = Sources.list_sources(tenant.id)
        prefill = prefill_from_session(session, tenant.id)

        {:ok,
         socket
         |> assign(tenant: tenant)
         |> assign(job: job)
         |> assign(career_page: career_page)
         |> assign(first_stage: first_stage)
         |> assign(application_fields: application_fields)
         |> assign(sources: sources)
         |> assign(prefill: prefill)
         |> assign(form: to_form(prefill, as: :application))
         |> assign(submitted: false)
         |> assign(duplicate: false)
         |> assign(duplicate_applied_at: nil)
         |> allow_upload(:resume,
           accept: ~w(.pdf .doc .docx),
           max_entries: 1,
           max_file_size: 10_000_000
         )}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <div class="max-w-2xl mx-auto py-12 px-4">
        <.link
          navigate={~p"/#{@tenant.slug}/careers/#{@job.id}"}
          class="text-blue-600 hover:text-blue-900"
        >
          &larr; Back to job
        </.link>

        <div
          :if={@duplicate}
          id="duplicate-notice"
          class="mt-8 bg-base-100 rounded-lg shadow p-8 text-center"
        >
          <h2 class="text-2xl font-bold text-base-content">
            {gettext("You have already applied")}
          </h2>
          <p class="mt-4 text-base-content/70">
            <%= if @duplicate_applied_at do %>
              {gettext("You applied to this position on %{date}.",
                date: Calendar.strftime(@duplicate_applied_at, "%b %d, %Y")
              )}
            <% else %>
              {gettext("You have already applied to this position.")}
            <% end %>
          </p>
          <div class="mt-6 space-y-4">
            <.link
              navigate={~p"/#{@tenant.slug}/portal/login"}
              class="inline-block px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              {gettext("View Your Application")}
            </.link>
            <div>
              <.link
                navigate={~p"/#{@tenant.slug}/careers"}
                class="text-blue-600 hover:text-blue-900"
              >
                {gettext("View other positions")}
              </.link>
            </div>
          </div>
        </div>

        <div :if={@submitted} class="mt-8 bg-base-100 rounded-lg shadow p-8 text-center">
          <h2 class="text-2xl font-bold text-base-content">{gettext("Thank you!")}</h2>
          <p class="mt-4 text-base-content/70">
            {gettext(
              "Your application has been submitted. Check your email — including spam — for a 10-minute code to track your application."
            )}
          </p>
          <div class="mt-6 space-y-4">
            <.link
              navigate={~p"/#{@tenant.slug}/portal/login"}
              class="inline-block px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 min-h-[44px]"
            >
              {gettext("Track your application")}
            </.link>
            <div>
              <.link
                navigate={~p"/#{@tenant.slug}/careers"}
                class="text-blue-600 hover:text-blue-900"
              >
                {gettext("View other positions")}
              </.link>
            </div>
          </div>
          <%= if email = @tenant.settings["support_email"] || @tenant.settings["contact_email"] do %>
            <div
              id="candidate-help"
              class="mt-8 rounded-lg bg-blue-50 dark:bg-blue-950 border border-blue-200 dark:border-blue-900 p-4 text-left"
            >
              <p class="text-sm font-medium text-blue-900 dark:text-blue-100">
                {gettext("Need help?")}
              </p>
              <p class="mt-1 text-sm text-blue-700 dark:text-blue-300">
                {gettext(
                  "Contact %{company} support or email us at %{email} if you have trouble with your application.",
                  company: @tenant.name,
                  email: email
                )}
              </p>
            </div>
          <% end %>
        </div>

        <div :if={!@submitted && !@duplicate} class="mt-8 bg-base-100 rounded-lg shadow p-8">
          <h2 class="text-2xl font-bold text-base-content">Apply for {@job.title}</h2>
          <p :if={@prefill != %{}} class="mt-2 text-sm text-blue-600">
            {gettext("Prefilled from your portal profile — you can edit before submitting.")}
          </p>

          <.form for={@form} id="apply-form" phx-submit="submit_application" class="mt-6 space-y-4">
            <.input field={@form[:name]} type="text" label={gettext("Full Name")} required />
            <.input field={@form[:email]} type="email" label={gettext("Email")} required />
            <.input field={@form[:phone]} type="text" label={gettext("Phone")} />

            <div :if={@sources != []}>
              <label class="block text-sm font-medium text-base-content/80 mb-1">
                How did you hear about us?
              </label>
              <select
                name="application[source]"
                class="select w-full"
              >
                <option value="">—</option>
                <option :for={source <- @sources} value={source.name}>{source.name}</option>
              </select>
            </div>

            <div :if={@application_fields != []} class="border-t pt-4 mt-4">
              <h3 class="text-sm font-medium text-base-content/80 mb-3">
                {gettext("Additional Information")}
              </h3>
              <div :for={field <- @application_fields} class="mb-3">
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

            <div id="resume-upload">
              <label class="block text-sm font-medium text-base-content/80 mb-1">
                Resume (PDF, DOC, DOCX - max 10MB)
              </label>
              <.live_file_input
                upload={@uploads.resume}
                class="block w-full text-sm text-base-content/50 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-blue-50 dark:file:bg-blue-950 file:text-blue-700 dark:file:text-blue-100 hover:file:bg-blue-100 dark:bg-blue-900 dark:hover:file:bg-blue-900 min-h-[44px]"
              />
              <div
                :for={entry <- @uploads.resume.entries}
                class="mt-3 flex flex-col gap-2 rounded-lg border border-base-300 bg-base-200 p-3"
              >
                <div class="flex items-center justify-between gap-2">
                  <div class="flex items-center gap-2 min-w-0">
                    <.icon name="hero-document" class="w-5 h-5 text-blue-600 shrink-0" />
                    <span class="text-sm font-medium text-base-content truncate">
                      {entry.client_name} &mdash; {format_bytes(entry.client_size)}
                    </span>
                    <span :if={entry.done?} class="text-green-600 text-sm">✓</span>
                  </div>
                  <button
                    type="button"
                    phx-click="cancel_upload"
                    phx-value-ref={entry.ref}
                    aria-label={gettext("Remove file")}
                    class="min-h-[44px] min-w-[44px] px-3 text-sm font-medium text-red-600 hover:text-red-800 hover:bg-red-50 rounded-lg shrink-0"
                  >
                    {gettext("Remove")}
                  </button>
                </div>
                <div :if={!entry.done?} class="w-full bg-base-300 rounded-full h-2">
                  <div
                    class="bg-blue-600 h-2 rounded-full transition-all"
                    style={"width: #{entry.progress}%"}
                  >
                  </div>
                </div>
                <p :if={!entry.done?} class="text-xs text-base-content/70">
                  {entry.progress}% {gettext("uploading...")}
                </p>
                <p :for={err <- upload_errors(@uploads.resume, entry)} class="text-red-500 text-sm">
                  {upload_error_to_string(err)}
                </p>
              </div>
              <p :for={err <- upload_errors(@uploads.resume)} class="text-red-500 text-sm mt-2">
                {upload_error_to_string(err)}
              </p>
            </div>

            <.button
              type="submit"
              class="w-full min-h-[44px]"
              style={"background-color: #{@career_page && @career_page.primary_color || "#3b82f6"}"}
              disabled={Enum.any?(@uploads.resume.entries, fn e -> !e.done? end)}
            >
              <%= if Enum.any?(@uploads.resume.entries, fn e -> !e.done? end) do %>
                <span class="inline-flex items-center gap-2">
                  <.icon name="hero-arrow-path" class="w-4 h-4 animate-spin" />
                  {gettext("Uploading...")}
                </span>
              <% else %>
                {gettext("Submit Application")}
              <% end %>
            </.button>
          </.form>
          <%= if email = @tenant.settings["support_email"] || @tenant.settings["contact_email"] do %>
            <div
              id="candidate-help"
              class="mt-6 rounded-lg bg-blue-50 dark:bg-blue-950 border border-blue-200 dark:border-blue-900 p-4"
            >
              <p class="text-sm font-medium text-blue-900 dark:text-blue-100">
                {gettext("Need help?")}
              </p>
              <p class="mt-1 text-sm text-blue-700 dark:text-blue-300">
                {gettext(
                  "Contact %{company} support or email us at %{email} if you have trouble with your application.",
                  company: @tenant.name,
                  email: email
                )}
              </p>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :resume, ref)}
  end

  def handle_event("submit_application", params, socket) do
    # Guard against silent nil resume when file was attempted but invalid/incomplete
    # Check for upload-level errors (too_large, not_accepted, too_many_files)
    upload_config = socket.assigns.uploads.resume
    general_errors = upload_errors(upload_config)

    entry_errors =
      Enum.flat_map(upload_config.entries, fn entry -> upload_errors(upload_config, entry) end)

    has_errors = general_errors != [] or entry_errors != []
    has_incomplete = Enum.any?(upload_config.entries, fn e -> not e.done? end)

    if has_errors or has_incomplete do
      {:noreply,
       socket
       |> put_flash(
         :error,
         gettext("Please fix the resume upload or remove the file to apply without a CV.")
       )}
    else
      tenant = socket.assigns.tenant
      job = socket.assigns.job
      application_params = Map.get(params, "application", %{})
      custom_fields_values = Map.get(params, "custom_fields", %{})

      candidate_attrs = %{
        "name" => application_params["name"],
        "email" => application_params["email"],
        "phone" => application_params["phone"],
        "tenant_id" => tenant.id
      }

      case Candidates.create_or_find(tenant.id, candidate_attrs) do
        {:ok, candidate} ->
          handle_candidate_found(socket, candidate, job, custom_fields_values, application_params)

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Please review the errors below"))}
      end
    end
  end

  defp handle_candidate_found(socket, candidate, job, custom_fields_values, application_params) do
    case find_existing_application(candidate.id, job.id) do
      %Treby.Pipeline.Application{} = existing ->
        {:noreply,
         socket
         |> assign(duplicate: true)
         |> assign(duplicate_applied_at: existing.applied_at)
         |> assign(submitted: false)}

      nil ->
        do_create_application(socket, candidate, job, custom_fields_values, application_params)
    end
  end

  defp find_existing_application(candidate_id, job_id) do
    import Ecto.Query

    Treby.Pipeline.Application
    |> where([a], a.candidate_id == ^candidate_id and a.job_id == ^job_id)
    |> order_by([a], asc: a.applied_at)
    |> limit(1)
    |> Treby.Repo.one()
  end

  defp do_create_application(socket, candidate, job, custom_fields_values, application_params) do
    tenant = socket.assigns.tenant

    resume_url =
      case consume_uploaded_entries(socket, :resume, fn %{path: path}, _entry ->
             key = "#{tenant.id}/resumes/#{candidate.id}/#{Path.basename(path)}"
             content = File.read!(path)

             case Treby.Uploads.upload_file(key, content, "application/pdf") do
               {:ok, _} -> {:ok, key}
               _ -> {:ok, nil}
             end
           end) do
        [url] -> url
        _ -> nil
      end

    application_attrs = %{
      "tenant_id" => tenant.id,
      "job_id" => job.id,
      "candidate_id" => candidate.id,
      "pipeline_stage_id" => socket.assigns.first_stage.id,
      "applied_at" => DateTime.utc_now(),
      "resume_url" => resume_url,
      "custom_fields" => custom_fields_values,
      "reviewed" => false,
      "source" => application_params["source"],
      "anagrafica" => %{
        "name" => application_params["name"],
        "email" => application_params["email"],
        "phone" => application_params["phone"]
      }
    }

    case Pipeline.create_application(application_attrs) do
      {:ok, application} ->
        create_welcome_conversation(application, candidate, tenant, job)
        notify_application(application)
        notify_team(application)
        {:noreply, assign(socket, submitted: true)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to submit application"))}
    end
  end

  defp create_welcome_conversation(application, candidate, tenant, job) do
    {:ok, conversation} =
      CandidatePortal.create_conversation(%{
        candidate_id: candidate.id,
        tenant_id: tenant.id,
        subject: gettext("Welcome - %{title}", title: job.title),
        context: "application",
        application_id: application.id
      })

    CandidatePortal.send_message(%{
      sender_type: "system",
      conversation_id: conversation.id,
      body:
        gettext(
          "Welcome! Thank you for applying for %{title}. We've received your application and will review it shortly. You can use this portal to communicate with our team.",
          title: job.title
        ),
      message_type: "text"
    })
  rescue
    _ -> :ok
  catch
    _ -> :ok
  end

  defp notify_application(application) do
    Treby.Notifications.notify_new_application_candidate(application)
  rescue
    _ -> :ok
  catch
    _ -> :ok
  end

  defp notify_team(application) do
    Treby.Notifications.notify_team_new_application(application)
  rescue
    _ -> :ok
  catch
    _ -> :ok
  end

  defp prefill_from_session(session, tenant_id) do
    with cid when is_binary(cid) <- session["candidate_id"],
         ^tenant_id <- session["candidate_tenant_id"],
         %Treby.Candidates.Candidate{} = candidate <-
           Treby.Repo.get(Treby.Candidates.Candidate, cid),
         true <- candidate.tenant_id == tenant_id do
      %{
        "name" => candidate.name,
        "email" => candidate.email,
        "phone" => candidate.phone || ""
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) or v == "" end)
      |> Map.new()
    else
      _ -> %{}
    end
  end

  defp upload_error_to_string(:too_large), do: gettext("File is too large (max 10MB)")

  defp upload_error_to_string(:not_accepted),
    do:
      gettext(
        "File type not accepted (use PDF, DOC, or DOCX). If you have a photo, convert it to PDF or contact support."
      )

  defp upload_error_to_string(:too_many_files), do: gettext("Only one file is allowed")
  defp upload_error_to_string(err), do: gettext("Upload error: %{reason}", reason: inspect(err))

  defp format_bytes(size) when is_integer(size) do
    cond do
      size >= 1_000_000 -> "#{Float.round(size / 1_000_000, 1)} MB"
      size >= 1000 -> "#{div(size, 1000)} KB"
      true -> "#{size} bytes"
    end
  end

  defp format_bytes(_), do: ""
end
