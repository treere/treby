defmodule TrebyWeb.SettingsLive.EmailTemplates do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, EmailTemplates}
  alias Treby.EmailTemplates.EmailTemplate

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

    templates = EmailTemplates.list_email_templates(tenant.id)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(templates: templates)
     |> assign(show_form: false)
     |> assign(editing_template: nil)
     |> assign(form: to_form(EmailTemplate.changeset(%EmailTemplate{}, %{}), as: :email_template))
     |> assign(preview_subject: "")
     |> assign(preview_body: "")
     |> assign(confirm_delete: nil)}
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
            <h1 class="text-2xl font-bold mt-2">{gettext("Message Templates")}</h1>
            <p class="mt-1 text-base-content/70">
              {gettext("Configure message templates for stage transitions")}
            </p>
          </div>
          <button
            phx-click="show_create_form"
            class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
          >
            + {gettext("Add Template")}
          </button>
        </div>

        <div :if={@show_form} class="mb-8 p-6 bg-base-100 rounded-lg shadow">
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
                placeholder={gettext("e.g. Rejection Message")}
              />
              <.input
                field={@form[:stage_type]}
                type="select"
                label={gettext("Trigger Stage")}
                options={[
                  {gettext("New Application"), "new"},
                  {gettext("Interview"), "interview"},
                  {gettext("Offer"), "offer"},
                  {gettext("Hired"), "hired"},
                  {gettext("Rejected"), "rejected"}
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

            <div
              :if={@preview_subject != "" || @preview_body != ""}
              class="p-4 bg-base-200 rounded-lg"
            >
              <h3 class="text-sm font-medium text-base-content/80 mb-2">{gettext("Preview")}</h3>
              <p class="text-sm text-base-content/70 mb-2">
                <strong>{gettext("Subject")}:</strong> {@preview_subject}
              </p>
              <div class="text-sm text-base-content/70" phx-no-curly-interpolation>
                {@preview_body}
              </div>
            </div>

            <div class="flex gap-2">
              <.button type="submit">{gettext("Save")}</.button>
              <.button type="button" phx-click="cancel_form" class="bg-gray-500">
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
                  {gettext("Name")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  {gettext("Stage Type")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  {gettext("Subject")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  {gettext("Actions")}
                </th>
              </tr>
            </thead>
            <tbody class="bg-base-100 divide-y divide-gray-200">
              <tr :for={template <- @templates} class="hover:bg-base-200">
                <td class="px-6 py-4 whitespace-nowrap font-medium text-base-content">
                  {template.name}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-base-content/70">
                  {template.stage_type}
                </td>
                <td class="px-6 py-4 text-base-content/70 max-w-xs truncate">{template.subject}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <button
                    phx-click="edit_template"
                    phx-value-template_id={template.id}
                    class="text-blue-600 hover:text-blue-900 mr-3"
                  >
                    {gettext("Edit")}
                  </button>
                  <button
                    phx-click="confirm_delete"
                    phx-value-id={template.id}
                    phx-value-title={gettext("Delete template")}
                    phx-value-message={
                      gettext(
                        "Are you sure you want to delete this message template? This action cannot be undone."
                      )
                    }
                    class="text-red-600 hover:text-red-900"
                  >
                    {gettext("Delete")}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
          <div :if={@templates == []} class="p-8 text-center text-base-content/50">
            {gettext("No message templates yet. Create your first template!")}
          </div>
        </div>
      </div>
    </Layouts.app>
    <.confirm_modal confirm_delete={@confirm_delete} on_confirm="do_delete_template" />
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
      candidate_name: gettext("John Doe"),
      job_title: gettext("Software Engineer"),
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
         |> put_flash(:info, gettext("Template saved"))}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, gettext("Only admins can manage message templates"))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(form: to_form(changeset))
         |> put_flash(:error, gettext("Please review the errors below"))}
    end
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

  def handle_event("do_delete_template", %{"id" => template_id}, socket) do
    template = EmailTemplates.get_email_template!(template_id)

    case EmailTemplates.delete_email_template(template, socket.assigns.current_user) do
      {:ok, _} ->
        templates = EmailTemplates.list_email_templates(socket.assigns.current_tenant.id)

        {:noreply,
         socket
         |> assign(templates: templates, confirm_delete: nil)
         |> put_flash(:info, gettext("Template deleted"))}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> assign(confirm_delete: nil)
         |> put_flash(:error, gettext("Only admins can delete message templates"))}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(confirm_delete: nil)
         |> put_flash(:error, gettext("Failed to delete template"))}
    end
  end
end
