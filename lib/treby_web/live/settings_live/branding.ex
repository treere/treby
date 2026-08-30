defmodule TrebyWeb.SettingsLive.Branding do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Careers}
  alias Treby.Careers.CareerPage

  def mount(params, session, socket) do
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

    career_page =
      Careers.get_career_page_by_tenant(tenant.id) ||
        %CareerPage{tenant_id: tenant.id, primary_color: "#3b82f6"}

    form = to_form(Careers.change_career_page(career_page))

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(career_page: career_page)
     |> assign(form: form)
     |> allow_upload(:logo,
       accept: ~w(.png .jpg .jpeg .svg),
       max_entries: 1,
       max_file_size: 5_000_000
     )}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <div class="mb-8">
          <.link navigate={~p"/app/settings"} class="text-blue-600 hover:text-blue-900 text-sm">
            &larr; Back to Settings
          </.link>
          <h1 class="text-2xl font-bold mt-2">Branding</h1>
          <p class="mt-1 text-base-content/70">Customize your career page appearance</p>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div class="bg-base-100 rounded-lg shadow p-6">
            <h2 class="text-lg font-semibold mb-4">Settings</h2>
            <.form
              for={@form}
              id="branding-form"
              phx-submit="save_branding"
              phx-change="validate_branding"
              class="space-y-4"
            >
              <.input
                field={@form[:title]}
                type="text"
                label="Page Title"
                placeholder="Join our team"
              />
              <.input
                field={@form[:description]}
                type="textarea"
                label="Description"
                placeholder="Help us build the future..."
              />
              <.input
                field={@form[:primary_color]}
                type="color"
                label="Primary Color"
              />

              <div>
                <label class="block text-sm font-medium text-base-content/80 mb-1">Logo</label>
                <.live_file_input
                  upload={@uploads.logo}
                  class="block w-full text-sm text-base-content/50 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-blue-50 dark:bg-blue-950 file:text-blue-700 dark:text-blue-100 hover:file:bg-blue-100"
                />
                <p :for={err <- upload_errors(@uploads.logo)} class="text-red-500 text-sm mt-1">
                  {upload_error_to_string(err)}
                </p>
              </div>

              <div class="flex items-center gap-2">
                <.input
                  field={@form[:published]}
                  type="checkbox"
                  label="Published"
                />
              </div>

              <.button type="submit" class="w-full">Save Branding</.button>
            </.form>
          </div>

          <div class="bg-base-100 rounded-lg shadow p-6">
            <h2 class="text-lg font-semibold mb-4">Preview</h2>
            <div class="border rounded-lg overflow-hidden">
              <div
                class="p-6 text-center text-white"
                style={"background-color: #{@form[:primary_color].value || "#3b82f6"}"}
              >
                <div :if={@career_page.logo_url} class="mb-4">
                  <img src={@career_page.logo_url} class="h-12 mx-auto" alt="Logo" />
                </div>
                <h3 class="text-xl font-bold">
                  {@form[:title].value || @current_tenant.name}
                </h3>
                <p :if={@form[:description].value} class="mt-2 text-sm opacity-90">
                  {@form[:description].value}
                </p>
              </div>
              <div class="p-4 bg-base-200">
                <p class="text-sm text-base-content/50 text-center">
                  Open positions will appear here
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("validate_branding", %{"career_page" => page_params}, socket) do
    form = to_form(Careers.change_career_page(socket.assigns.career_page, page_params))
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save_branding", %{"career_page" => page_params}, socket) do
    logo_url =
      case consume_uploaded_entries(socket, :logo, fn %{path: path}, _entry ->
             key = "#{socket.assigns.current_tenant.id}/logos/#{Path.basename(path)}"
             content = File.read!(path)
             ext = Path.extname(path) |> String.trim_leading(".")
             content_type = "image/#{if ext == "jpg", do: "jpeg", else: ext}"

             case Treby.Uploads.upload_file(key, content, content_type) do
               {:ok, _} -> {:ok, Treby.Uploads.get_presigned_url(key)}
               _ -> {:ok, nil}
             end
           end) do
        [url] -> url
        _ -> nil
      end

    params =
      if logo_url do
        Map.put(page_params, "logo_url", logo_url)
      else
        page_params
      end

    result =
      case socket.assigns.career_page do
        %{id: nil} ->
          Careers.create_career_page(
            Map.put(params, "tenant_id", socket.assigns.current_tenant.id)
          )

        career_page ->
          Careers.update_career_page(career_page, params)
      end

    case result do
      {:ok, career_page} ->
        {:noreply,
         socket
         |> assign(career_page: career_page)
         |> assign(form: to_form(Careers.change_career_page(career_page)))
         |> put_flash(:info, "Branding saved")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(form: to_form(changeset))
         |> put_flash(:error, "Please review the errors below")}
    end
  end

  defp upload_error_to_string(:too_large), do: "File is too large (max 5MB)"
  defp upload_error_to_string(:not_accepted), do: "File type not accepted (use PNG, JPG, or SVG)"
  defp upload_error_to_string(:too_many_files), do: "Only one file is allowed"
  defp upload_error_to_string(err), do: "Upload error: #{inspect(err)}"
end
