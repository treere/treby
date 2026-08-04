defmodule TrebyWeb.CandidatesLive.Merge do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Candidates, Pipeline}

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])
    auto_merged = Candidates.auto_merge_exact_email(tenant.id, user)
    groups = prepare_groups(tenant.id, MapSet.new())

    socket =
      if auto_merged.merged > 0 do
        put_flash(
          socket,
          :info,
          "Auto-merged #{auto_merged.merged} exact-email duplicate #{plural(auto_merged.merged)}"
        )
      else
        socket
      end

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(groups: groups)
     |> assign(selected_primary: initial_selections(groups))
     |> assign(dismissed: MapSet.new())}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <div class="flex justify-between items-center mb-8">
          <div>
            <.link navigate={~p"/app/candidates"} class="text-blue-600 hover:text-blue-900 text-sm">
              &larr; Back to Candidates
            </.link>
            <h1 class="text-2xl font-bold mt-2">Merge Duplicates</h1>
            <p class="text-sm text-gray-500 mt-1">
              Candidates that look like they may be the same person. Review the evidence and merge them into a single profile — or dismiss the suggestion.
            </p>
          </div>
        </div>

        <div
          :if={@groups == []}
          class="mt-8 bg-white rounded-lg shadow p-10 text-center"
        >
          <div class="mx-auto w-14 h-14 rounded-full bg-green-100 flex items-center justify-center">
            <.icon name="hero-check-circle" class="w-8 h-8 text-green-600" />
          </div>
          <h2 class="mt-4 text-lg font-semibold text-gray-900">No duplicate candidates</h2>
          <p class="mt-2 text-sm text-gray-500 max-w-md mx-auto">
            We didn't find any candidates that look like duplicates right now. New candidates are checked automatically as they come in.
          </p>
        </div>

        <div :for={group <- @groups} class="bg-white rounded-lg shadow p-6 mb-6">
          <div class="flex items-center gap-3 mb-4">
            <h2 class="text-lg font-semibold text-gray-900">
              {length(group.candidates)} profiles may be the same person
            </h2>
            <%= case group.confidence do %>
              <% :high -> %>
                <span class="text-xs font-medium bg-green-100 text-green-800 px-2 py-0.5 rounded-full">
                  High confidence
                </span>
              <% :medium -> %>
                <span class="text-xs font-medium bg-yellow-100 text-yellow-800 px-2 py-0.5 rounded-full">
                  Medium confidence
                </span>
            <% end %>
            <span class="text-xs text-gray-500 bg-gray-100 px-2 py-0.5 rounded-full">
              {signal_label(group.signal)}
            </span>
            <span
              :if={group.auto_merge}
              class="text-xs font-medium bg-blue-100 text-blue-800 px-2 py-0.5 rounded-full"
            >
              Same email — safe to merge
            </span>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead>
                <tr class="text-left text-xs text-gray-500 border-b border-gray-200">
                  <th class="py-2 pr-3">Primary</th>
                  <th class="py-2 pr-3">Name</th>
                  <th class="py-2 pr-3">Email</th>
                  <th class="py-2 pr-3">Phone</th>
                  <th class="py-2 pr-3">LinkedIn</th>
                  <th class="py-2">Applications</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  :for={candidate <- group.candidates}
                  class="border-b border-gray-100 last:border-0"
                >
                  <td class="py-2 pr-3">
                    <input
                      type="radio"
                      name={"primary-#{group.id}"}
                      value={candidate.id}
                      phx-click="select_primary"
                      phx-value-group_id={group.id}
                      phx-value-candidate_id={candidate.id}
                      checked={@selected_primary[group.id] == candidate.id}
                      class="w-4 h-4"
                    />
                  </td>
                  <td class="py-2 pr-3 font-medium text-gray-900">
                    <span
                      :if={@selected_primary[group.id] == candidate.id}
                      class="text-xs text-blue-600 font-semibold mr-1"
                    >
                      ●
                    </span>
                    {candidate.name}
                  </td>
                  <td class="py-2 pr-3 text-gray-600">{candidate.email}</td>
                  <td class="py-2 pr-3 text-gray-600">{candidate.phone || "—"}</td>
                  <td class="py-2 pr-3 text-gray-600">
                    <a
                      :if={candidate.linkedin_url}
                      href={candidate.linkedin_url}
                      target="_blank"
                      class="text-blue-600 hover:text-blue-900"
                    >
                      Profile
                    </a>
                    <span :if={!candidate.linkedin_url}>—</span>
                  </td>
                  <td class="py-2 text-gray-600">{candidate.application_count}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="flex items-center gap-3 mt-5">
            <button
              phx-click="merge_group"
              phx-value-group_id={group.id}
              class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 text-sm font-medium"
            >
              Merge {length(group.candidates)} into primary
            </button>
            <button
              phx-click="dismiss_group"
              phx-value-group_id={group.id}
              class="px-4 py-2 rounded-lg border border-gray-300 text-sm font-medium text-gray-700 hover:bg-gray-50"
            >
              Dismiss
            </button>
            <p class="text-xs text-gray-500">
              The primary profile keeps all applications, email threads, and activity. The others are archived.
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event(
        "select_primary",
        %{"group_id" => group_id, "candidate_id" => candidate_id},
        socket
      ) do
    selected_primary = Map.put(socket.assigns.selected_primary, group_id, candidate_id)
    {:noreply, assign(socket, selected_primary: selected_primary)}
  end

  def handle_event("merge_group", %{"group_id" => group_id}, socket) do
    tenant_id = socket.assigns.current_tenant.id
    actor = socket.assigns.current_user

    case find_group(socket.assigns.groups, group_id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Group not found. It may have been merged already.")}

      group ->
        primary_id = socket.assigns.selected_primary[group_id] || group.default_primary_id
        primary = Enum.find(group.candidates, &(&1.id == primary_id))
        absorbed = Enum.reject(group.candidates, &(&1.id == primary_id))

        case Candidates.merge_candidates(primary, absorbed, actor) do
          {:ok, %{primary: merged_primary}} ->
            groups = prepare_groups(tenant_id, socket.assigns.dismissed)

            {:noreply,
             socket
             |> assign(groups: groups)
             |> assign(selected_primary: initial_selections(groups))
             |> put_flash(
               :info,
               "Merged #{length(absorbed) + 1} profiles into #{merged_primary.name}"
             )}

          {:error, reason} ->
            {:noreply, put_flash(socket, :error, "Merge failed: #{format_error(reason)}")}
        end
    end
  end

  def handle_event("dismiss_group", %{"group_id" => group_id}, socket) do
    dismissed = MapSet.put(socket.assigns.dismissed, group_id)
    groups = prepare_groups(socket.assigns.current_tenant.id, dismissed)

    {:noreply,
     socket
     |> assign(groups: groups)
     |> assign(dismissed: dismissed)
     |> assign(selected_primary: initial_selections(groups))
     |> put_flash(:info, "Suggestion dismissed")}
  end

  defp find_group(groups, group_id) do
    Enum.find(groups, &(&1.id == group_id))
  end

  defp prepare_groups(tenant_id, dismissed) do
    Candidates.list_duplicate_groups(tenant_id)
    |> Enum.reject(fn group -> MapSet.member?(dismissed, group.id) end)
    |> Enum.map(fn group ->
      candidate_ids = Enum.map(group.candidates, & &1.id)
      counts = Pipeline.candidate_application_counts(tenant_id, candidate_ids)

      candidates =
        Enum.map(group.candidates, fn candidate ->
          Map.put(candidate, :application_count, Map.get(counts, candidate.id, 0))
        end)

      Map.put(group, :candidates, candidates)
    end)
  end

  defp initial_selections(groups) do
    Map.new(groups, &{&1.id, &1.default_primary_id})
  end

  defp signal_label(:exact_email), do: "Exact email match"
  defp signal_label(:phone_name), do: "Phone + name match"
  defp signal_label(:name_local_part), do: "Name + email match"
  defp signal_label(_), do: "Match"

  defp format_error(:no_candidates_to_merge), do: "No candidates to merge"
  defp format_error(:primary_is_tombstoned), do: "The primary profile was already merged"

  defp format_error(:cannot_merge_tombstoned_candidate),
    do: "One of the profiles was already merged"

  defp format_error(:cannot_merge_with_itself), do: "A profile cannot be merged with itself"
  defp format_error(:cross_tenant_merge), do: "Profiles belong to different workspaces"
  defp format_error(reason), do: inspect(reason)

  defp plural(1), do: "group"
  defp plural(_), do: "groups"
end
