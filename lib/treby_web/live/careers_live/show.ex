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
        already_applied? = already_applied?(session, tenant.id, job.id)

        socket =
          socket
          |> assign(tenant: tenant)
          |> assign(job: job)
          |> assign(career_page: career_page)
          |> assign(already_applied: already_applied?)

        maybe_track_view(socket, tenant, job, params, session)

        {:ok, socket}
    end
  end

  defp already_applied?(session, tenant_id, job_id) do
    with cid when is_binary(cid) <- session["candidate_id"],
         ^tenant_id <- session["candidate_tenant_id"] do
      import Ecto.Query

      Treby.Pipeline.Application
      |> where([a], a.candidate_id == ^cid and a.job_id == ^job_id and a.tenant_id == ^tenant_id)
      |> Treby.Repo.exists?()
    else
      _ -> false
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
    <div class="min-h-screen bg-zinc-50 dark:bg-zinc-800">
      <div class="max-w-3xl mx-auto py-12 px-4">
        <.link navigate={~p"/#{@tenant.slug}/careers"} class="text-primary hover:text-primary/80">
          &larr; Back to all positions
        </.link>

        <.card :if={@job && @job.status == "open"} class="mt-8">
          <div :if={@career_page} class="flex items-center gap-4 mb-6">
            <img
              :if={@career_page.logo_url}
              src={@career_page.logo_url}
              class="h-12"
              alt={@tenant.name}
            />
            <div>
              <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">{@tenant.name}</h2>
              <p :if={@career_page.description} class="text-sm text-zinc-400 dark:text-zinc-500">
                {@career_page.description}
              </p>
            </div>
          </div>

          <h1 class="text-3xl font-bold text-zinc-900 dark:text-zinc-100">{@job.title}</h1>

          <div class="mt-3 flex flex-wrap items-center gap-3 text-sm text-zinc-500 dark:text-zinc-400">
            <span :if={@job.salary_range} class="inline-flex items-center gap-1">
              <.icon name="hero-banknotes" class="w-4 h-4" /> {@job.salary_range}
            </span>
            <span :if={@job.location} class="inline-flex items-center gap-1">
              <.icon name="hero-map-pin" class="w-4 h-4" /> {@job.location}
            </span>
            <.badge :if={@job.employment_type} variant="default">
              {Treby.Jobs.Job.employment_type_label(@job.employment_type)}
            </.badge>
            <.badge :if={@job.workplace_type} variant="default">
              {Treby.Jobs.Job.workplace_type_label(@job.workplace_type)}
            </.badge>
            <span class="inline-flex items-center gap-1">
              <.icon name="hero-calendar" class="w-4 h-4" />
              {gettext("Posted")} {Calendar.strftime(@job.inserted_at, "%b %d, %Y")}
            </span>
          </div>

          <div class="mt-8 prose max-w-none">
            <p class="whitespace-pre-wrap text-zinc-900 dark:text-zinc-100/80">{@job.description}</p>
          </div>

          <.button
            :if={!@already_applied}
            variant="primary"
            navigate={~p"/#{@tenant.slug}/careers/#{@job.id}/apply"}
            class="mt-8"
            style={"background-color: #{@career_page && @career_page.primary_color || "#3b82f6"}"}
          >
            {gettext("Apply Now")}
          </.button>
          <.button
            :if={@already_applied}
            variant="primary"
            navigate={~p"/#{@tenant.slug}/portal"}
            class="mt-8"
          >
            {gettext("Already applied — View status")}
          </.button>
        </.card>

        <.card :if={@job && @job.status != "open"} class="mt-8 text-center">
          <h1 class="text-2xl font-bold text-zinc-900 dark:text-zinc-100">
            {gettext("This position is no longer available")}
          </h1>
          <p class="mt-4 text-zinc-500 dark:text-zinc-400">
            The job you're looking for has been closed or removed.
          </p>
          <.button variant="ghost" navigate={~p"/#{@tenant.slug}/careers"} class="mt-6">
            View other positions
          </.button>
        </.card>

        <.card :if={!@job} class="mt-8 text-center">
          <h1 class="text-2xl font-bold text-zinc-900 dark:text-zinc-100">
            {gettext("Position not found")}
          </h1>
          <p class="mt-4 text-zinc-500 dark:text-zinc-400">
            The job you're looking for doesn't exist or has been removed.
          </p>
          <.button variant="ghost" navigate={~p"/#{@tenant.slug}/careers"} class="mt-6">
            View other positions
          </.button>
        </.card>
      </div>
    </div>
    """
  end
end
