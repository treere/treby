defmodule TrebyWeb.CareersLive.Apply do
  use TrebyWeb, :live_view

  alias Treby.{Tenants, Jobs, Candidates, Pipeline, Careers}

  def mount(%{"tenant_slug" => tenant_slug, "job_id" => job_id}, _session, socket) do
    tenant = Tenants.get_tenant_by_slug!(tenant_slug)
    job = Jobs.get_job!(tenant.id, job_id)
    career_page = Careers.get_published_career_page_by_tenant(tenant.id)
    stages = Pipeline.list_pipeline_stages(tenant.id)
    first_stage = List.first(stages)

    {:ok,
     socket
     |> assign(tenant: tenant)
     |> assign(job: job)
     |> assign(career_page: career_page)
     |> assign(first_stage: first_stage)
     |> assign(form: to_form(%{}, as: :application))
     |> assign(submitted: false)}
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

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Resume (PDF)</label>
              <.live_file_input
                upload={@uploads.resume}
                class="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
              />
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

  def handle_params(_params, _uri, socket) do
    {:noreply,
     socket
     |> allow_upload(:resume, accept: ~w(.pdf), max_entries: 1)}
  end

  def handle_event("submit_application", %{"application" => application_params}, socket) do
    tenant = socket.assigns.tenant
    job = socket.assigns.job

    candidate_attrs = %{
      "name" => application_params["name"],
      "email" => application_params["email"],
      "phone" => application_params["phone"],
      "tenant_id" => tenant.id
    }

    {:ok, candidate} = Candidates.find_or_create_candidate(tenant.id, candidate_attrs)

    resume_url =
      case consume_uploaded_entries(socket, :resume, fn %{path: path}, _entry ->
             key = "resumes/#{candidate.id}/#{Path.basename(path)}"
             content = File.read!(path)

             case Treby.Uploads.upload_file(key, content, "application/pdf") do
               {:ok, _} -> {:ok, Treby.Uploads.get_presigned_url(key)}
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
      "resume_url" => resume_url
    }

    case Pipeline.create_application(application_attrs) do
      {:ok, _application} ->
        {:noreply, assign(socket, submitted: true)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to submit application")}
    end
  end
end
