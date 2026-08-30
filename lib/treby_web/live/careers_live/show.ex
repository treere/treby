defmodule TrebyWeb.CareersLive.Show do
  use TrebyWeb, :live_view

  alias Treby.{Tenants, Jobs, Careers, JobViews}
  require Logger

  def mount(%{"tenant_slug" => tenant_slug, "job_id" => job_id} = params, session, socket) do
    socket = set_locale_from_session(socket, session)
    tenant = Tenants.get_tenant_by_slug!(tenant_slug)

    case Jobs.get_job(tenant.id, job_id) do
      nil ->
        {:ok, redirect(socket, to: ~p"/404")}

      job ->
        career_page = Careers.get_published_career_page_by_tenant(tenant.id)

        socket =
          socket
          |> assign(tenant: tenant)
          |> assign(job: job)
          |> assign(career_page: career_page)

        maybe_track_view(socket, tenant, job, params, session)

        {:ok, socket}
    end
  end

  defp maybe_track_view(socket, tenant, job, params, session) do
    if job.status == "open" do
      try do
        is_team =
          case session["user_id"] do
            nil ->
              false

            uid ->
              case Treby.Repo.get(Treby.Accounts.User, uid) do
                nil -> false
                user -> user.tenant_id == tenant.id
              end
          end

        unless is_team do
          remote_ip = get_remote_ip(socket)
          user_agent = get_user_agent(socket)
          referer = get_referer(socket)
          utm_source = params["utm_source"] || extract_utm_from_uri(socket)

          session_hash = JobViews.session_hash(remote_ip, user_agent)

          case JobViews.track_view(%{
                 job_id: job.id,
                 tenant_id: tenant.id,
                 session_hash: session_hash,
                 viewed_at: DateTime.utc_now() |> DateTime.truncate(:second),
                 referer: referer,
                 utm_source: utm_source,
                 user_agent: user_agent
               }) do
            {:ok, _} ->
              :ok

            {:skip, _} ->
              :ok

            {:error, changeset} ->
              Logger.warning("Failed to track job view: #{inspect(changeset)}")
          end
        end
      rescue
        e -> Logger.warning("Failed to track job view: #{inspect(e)}")
      catch
        _, e -> Logger.warning("Failed to track job view: #{inspect(e)}")
      end
    end
  end

  defp get_remote_ip(socket) do
    case get_connect_info(socket, :peer_data) do
      %{address: addr} when is_tuple(addr) -> addr |> :inet.ntoa() |> to_string()
      _ -> "unknown"
    end
  rescue
    _ -> "unknown"
  catch
    _, _ -> "unknown"
  end

  defp get_user_agent(socket) do
    case get_connect_info(socket, :user_agent) do
      ua when is_binary(ua) and ua != "" -> ua
      _ -> get_header(socket, "user-agent")
    end
  rescue
    _ -> get_header(socket, "user-agent")
  catch
    _, _ -> get_header(socket, "user-agent")
  end

  defp get_referer(socket) do
    get_header(socket, "referer") || get_header(socket, "referrer")
  end

  defp get_header(socket, header) do
    case get_connect_info(socket, :x_headers) do
      headers when is_list(headers) ->
        Enum.find_value(headers, fn {k, v} -> if String.downcase(k) == header, do: v end)

      _ ->
        nil
    end
  rescue
    _ -> nil
  catch
    _, _ -> nil
  end

  defp extract_utm_from_uri(socket) do
    case get_connect_info(socket, :uri) do
      %URI{query: query} when is_binary(query) and query != "" ->
        URI.decode_query(query)["utm_source"]

      _ ->
        nil
    end
  rescue
    _ -> nil
  catch
    _, _ -> nil
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <div class="max-w-3xl mx-auto py-12 px-4">
        <.link navigate={~p"/#{@tenant.slug}/careers"} class="text-blue-600 hover:text-blue-900">
          &larr; Back to all positions
        </.link>

        <div :if={@job && @job.status == "open"} class="mt-8 bg-base-100 rounded-lg shadow p-8">
          <div :if={@career_page} class="flex items-center gap-4 mb-6">
            <img
              :if={@career_page.logo_url}
              src={@career_page.logo_url}
              class="h-12"
              alt={@tenant.name}
            />
            <div>
              <h2 class="text-lg font-semibold text-base-content">{@tenant.name}</h2>
              <p :if={@career_page.description} class="text-sm text-base-content/50">
                {@career_page.description}
              </p>
            </div>
          </div>

          <h1 class="text-3xl font-bold text-base-content">{@job.title}</h1>

          <p :if={@job.salary_range} class="mt-2 text-base-content/70">{@job.salary_range}</p>

          <div class="mt-8 prose max-w-none">
            <p class="whitespace-pre-wrap text-base-content/80">{@job.description}</p>
          </div>

          <.link
            navigate={~p"/#{@tenant.slug}/careers/#{@job.id}/apply"}
            class="mt-8 inline-block px-6 py-3 text-white font-semibold rounded-lg hover:opacity-90"
            style={"background-color: #{@career_page && @career_page.primary_color || "#3b82f6"}"}
          >
            Apply Now
          </.link>
        </div>

        <div
          :if={@job && @job.status != "open"}
          class="mt-8 bg-base-100 rounded-lg shadow p-8 text-center"
        >
          <h1 class="text-2xl font-bold text-base-content">This position is no longer available</h1>
          <p class="mt-4 text-base-content/70">
            The job you're looking for has been closed or removed.
          </p>
          <.link
            navigate={~p"/#{@tenant.slug}/careers"}
            class="mt-6 inline-block text-blue-600 hover:text-blue-900"
          >
            View other positions
          </.link>
        </div>

        <div :if={!@job} class="mt-8 bg-base-100 rounded-lg shadow p-8 text-center">
          <h1 class="text-2xl font-bold text-base-content">Position not found</h1>
          <p class="mt-4 text-base-content/70">
            The job you're looking for doesn't exist or has been removed.
          </p>
          <.link
            navigate={~p"/#{@tenant.slug}/careers"}
            class="mt-6 inline-block text-blue-600 hover:text-blue-900"
          >
            View other positions
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
