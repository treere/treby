defmodule TrebyWeb.SettingsLive.EmailTemplates do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, EmailTemplates}
  alias Treby.EmailTemplates.EmailTemplate

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])
    templates = EmailTemplates.list_email_templates(tenant.id)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(templates: templates)
     |> assign(show_form: false)
     |> assign(editing_template: nil)
     |> assign(form: to_form(EmailTemplate.changeset(%EmailTemplate{}, %{}), as: :email_template))
     |> assign(preview_subject: "")
     |> assign(preview_body: "")}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <div class="flex justify-between items-center mb-8">
          <div>
            <.link navigate={~p"/app/settings"} class="text-blue-600 hover:text-blue-900 text-sm">
              &larr; {gettext("Back to Settings")}
            </.link>
            <h1 class="text-2xl font-bold mt-2">{gettext("Email Templates")}</h1>
            <p class="mt-1 text-gray-600">
              {gettext("Configure email templates for stage transitions")}
            </p>
          </div>
          <button
            phx-click="show_create_form"
            class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
          >
            + {gettext("Add Template")}
          </button>
        </div>

        <div :if={@show_form} class="mb-8 p-6 bg-white rounded-lg shadow">
          <h2 class="text-lg font-semibold mb-4">
            {if @editing_template, do: gettext("Edit Template"), else: gettext("New Template")}
          </h2>
          <.form
            for={@form}
            id="email-template-form"
            phx-submit="save_template"
            phx-change="preview_template"
            class="space-y-4"
          >
            <div class="grid grid-cols-2 gap-4">
              <.input
                field={@form[:name]}
                type="text"
                label={gettext("Template Name")}
                placeholder={gettext("e.g. Rejection Email")}
              />
              <.input
                field={@form[:stage_type]}
                type="select"
                label={gettext("Trigger Stage")}
                options={[
                  {"Rejected", "rejected"},
                  {"Hired", "hired"}
                ]}
              />
            </div>

            <.input
              field={@form[:subject]}
              type="text"
              label={gettext("Subject")}
              placeholder={gettext("e.g. Update on your application for {job_title}")}
            />

            <.input
              field={@form[:body]}
              type="textarea"
              label={gettext("Body (HTML)")}
              rows="8"
              placeholder={
                gettext(
                  "Use variables: {candidate_name}, {job_title}, {company_name}, {stage_name}, {recruiter_name}"
                )
              }
            />

            <div :if={@preview_subject != "" || @preview_body != ""} class="p-4 bg-gray-50 rounded-lg">
              <h3 class="text-sm font-medium text-gray-700 mb-2">{gettext("Preview")}</h3>
              <p class="text-sm text-gray-600 mb-2">
                <strong>{gettext("Subject")}:</strong> {@preview_subject}
              </p>
              <div class="text-sm text-gray-600" phx-no-curly-interpolation>{@preview_body}</div>
            </div>

            <div class="flex gap-2">
              <.button type="submit">{gettext("Save")}</.button>
              <.button type="button" phx-click="cancel_form" class="bg-gray-500">
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
                  {gettext("Name")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  {gettext("Stage Type")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  {gettext("Subject")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  {gettext("Actions")}
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr :for={template <- @templates} class="hover:bg-gray-50">
                <td class="px-6 py-4 whitespace-nowrap font-medium text-gray-900">{template.name}</td>
                <td class="px-6 py-4 whitespace-nowrap text-gray-600">{template.stage_type}</td>
                <td class="px-6 py-4 text-gray-600 max-w-xs truncate">{template.subject}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <button
                    phx-click="edit_template"
                    phx-value-template_id={template.id}
                    class="text-blue-600 hover:text-blue-900 mr-3"
                  >
                    {gettext("Edit")}
                  </button>
                  <button
                    phx-click="delete_template"
                    phx-value-template_id={template.id}
                    class="text-red-600 hover:text-red-900"
                  >
                    {gettext("Delete")}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
          <div :if={@templates == []} class="p-8 text-center text-gray-500">
            {gettext("No email templates yet. Create your first template!")}
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("show_create_form", _, socket) do
    form =
      to_form(
        %{
          "name" => "",
          "stage_type" => "rejected",
          "subject" => "",
          "body" => "",
          "tenant_id" => socket.assigns.current_tenant.id
        },
        as: :email_template
      )

    {:noreply, assign(socket, show_form: true, editing_template: nil, form: form)}
  end

  def handle_event("cancel_form", _, socket) do
    {:noreply, assign(socket, show_form: false, editing_template: nil)}
  end

  def handle_event("edit_template", %{"template_id" => template_id}, socket) do
    template = EmailTemplates.get_email_template!(template_id)

    form =
      to_form(
        %{
          "name" => template.name,
          "stage_type" => template.stage_type,
          "subject" => template.subject,
          "body" => template.body,
          "tenant_id" => socket.assigns.current_tenant.id
        },
        as: :email_template
      )

    {:noreply, assign(socket, show_form: true, editing_template: template, form: form)}
  end

  def handle_event("preview_template", params, socket) do
    template_params = Map.get(params, "email_template", %{})

    preview_template = %EmailTemplate{
      subject: Map.get(template_params, "subject", ""),
      body: Map.get(template_params, "body", "")
    }

    sample_assigns = %{
      candidate_name: "John Doe",
      job_title: "Software Engineer",
      company_name: socket.assigns.current_tenant.name,
      stage_name: "Interview",
      recruiter_name: socket.assigns.current_user.name
    }

    {preview_subject, preview_body} =
      EmailTemplates.render_email(preview_template, sample_assigns)

    {:noreply, assign(socket, preview_subject: preview_subject, preview_body: preview_body)}
  end

  def handle_event("save_template", params, socket) do
    template_params = Map.get(params, "email_template", %{})
    attrs = Map.put(template_params, "tenant_id", socket.assigns.current_tenant.id)

    result =
      case socket.assigns.editing_template do
        nil ->
          EmailTemplates.upsert_email_template(attrs, socket.assigns.current_user)

        template ->
          template
          |> EmailTemplate.changeset(attrs)
          |> Treby.Repo.update()
          |> then(fn result -> result end)
      end

    case result do
      {:ok, _template} ->
        templates = EmailTemplates.list_email_templates(socket.assigns.current_tenant.id)

        {:noreply,
         socket
         |> assign(templates: templates, show_form: false, editing_template: nil)
         |> put_flash(:info, "Template saved")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "Only admins can manage email templates")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("delete_template", %{"template_id" => template_id}, socket) do
    template = EmailTemplates.get_email_template!(template_id)

    case EmailTemplates.delete_email_template(template, socket.assigns.current_user) do
      {:ok, _} ->
        templates = EmailTemplates.list_email_templates(socket.assigns.current_tenant.id)

        {:noreply, assign(socket, templates: templates) |> put_flash(:info, "Template deleted")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "Only admins can delete email templates")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete template")}
    end
  end
end
