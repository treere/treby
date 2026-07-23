defmodule TrebyWeb.CareersLive.Apply do
  use TrebyWeb, :live_view

  alias Treby.{Tenants, Jobs, Candidates, Pipeline, Careers, Customization}

  def mount(%{"tenant_slug" => tenant_slug, "job_id" => job_id}, session, socket) do
    socket = set_locale_from_session(socket, session)
    tenant = Tenants.get_tenant_by_slug!(tenant_slug)
    job = Jobs.get_job!(tenant.id, job_id)
    career_page = Careers.get_published_career_page_by_tenant(tenant.id)
    stages = Pipeline.list_pipeline_stages(tenant.id)
    first_stage = List.first(stages)
    application_fields = Customization.list_custom_fields_for(tenant.id, "application")

    {:ok,
     socket
     |> assign(tenant: tenant)
     |> assign(job: job)
     |> assign(career_page: career_page)
     |> assign(first_stage: first_stage)
     |> assign(application_fields: application_fields)
     |> assign(form: to_form(%{}, as: :application))
     |> assign(submitted: false)
     |> allow_upload(:resume,
       accept: ~w(.pdf .doc .docx),
       max_entries: 1,
       max_file_size: 10_000_000
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <div class="max-w-2xl mx-auto py-12 px-4">
        <.link
          navigate={~p"/#{@tenant.slug}/careers/#{@job.id}"}
          class="text-blue-600 hover:text-blue-900"
        >
          &larr; Back to job
        </.link>

        <div :if={@submitted} class="mt-8 bg-white rounded-lg shadow p-8 text-center">
          <h2 class="text-2xl font-bold text-gray-900">Thank you!</h2>
          <p class="mt-4 text-gray-600">
            Your application has been submitted. We'll be in touch soon.
          </p>
          <.link
            navigate={~p"/#{@tenant.slug}/careers"}
            class="mt-6 inline-block text-blue-600 hover:text-blue-900"
          >
            View other positions
          </.link>
        </div>

        <div :if={!@submitted} class="mt-8 bg-white rounded-lg shadow p-8">
          <h2 class="text-2xl font-bold text-gray-900">Apply for {@job.title}</h2>

          <.form for={@form} id="apply-form" phx-submit="submit_application" class="mt-6 space-y-4">
            <.input field={@form[:name]} type="text" label="Full Name" required />
            <.input field={@form[:email]} type="email" label="Email" required />
            <.input field={@form[:phone]} type="text" label="Phone" />

            <div :if={@application_fields != []} class="border-t pt-4 mt-4">
              <h3 class="text-sm font-medium text-gray-700 mb-3">Additional Information</h3>
              <div :for={field <- @application_fields} class="mb-3">
                <%= cond do %>
                  <% field.field_type == "select" -> %>
                    <label class="block text-sm font-medium text-gray-700 mb-1">{field.name}</label>
                    <select
                      name={"custom_fields[#{field.id}]"}
                      class="block w-full rounded-lg border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
                    >
                      <option value="">—</option>
                      <option :for={opt <- field.options} value={opt}>{opt}</option>
                    </select>
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

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">
                Resume (PDF, DOC, DOCX - max 10MB)
              </label>
              <.live_file_input
                upload={@uploads.resume}
                class="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
              />
              <p :for={err <- upload_errors(@uploads.resume)} class="text-red-500 text-sm mt-1">
                {upload_error_to_string(err)}
              </p>
            </div>

            <.button
              type="submit"
              class="w-full"
              style={"background-color: #{@career_page && @career_page.primary_color || "#3b82f6"}"}
            >
              Submit Application
            </.button>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("submit_application", params, socket) do
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

    {:ok, candidate} = Candidates.find_or_create_candidate(tenant.id, candidate_attrs)

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
      "reviewed" => false
    }

    case Pipeline.create_application(application_attrs) do
      {:ok, _application} ->
        {:noreply, assign(socket, submitted: true)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to submit application")}
    end
  end

  defp upload_error_to_string(:too_large), do: "File is too large (max 10MB)"
  defp upload_error_to_string(:not_accepted), do: "File type not accepted (use PDF, DOC, or DOCX)"
  defp upload_error_to_string(:too_many_files), do: "Only one file is allowed"
  defp upload_error_to_string(err), do: "Upload error: #{inspect(err)}"
end
