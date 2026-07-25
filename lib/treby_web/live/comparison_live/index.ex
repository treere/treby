defmodule TrebyWeb.ComparisonLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Candidates, Comparison}

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])

    candidates = Candidates.list_candidates(tenant.id)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(candidates: candidates)
     |> assign(selected_ids: [])
     |> assign(comparison_data: nil)
     |> assign(error: nil)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <h1 class="text-2xl font-bold">{gettext("Compare Candidates")}</h1>
        <p class="mt-2 text-gray-600">{gettext("Select 2-3 candidates to compare side by side")}</p>

        <div :if={@error} class="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700">
          {@error}
        </div>

        <div :if={not @comparison_data} class="mt-8">
          <div class="flex items-center justify-between mb-4">
            <span class="text-sm text-gray-600">
              {gettext("Selected: %{count}/3", count: length(@selected_ids))}
            </span>
            <.link
              :if={length(@selected_ids) >= 2}
              phx-click="compare"
              class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              {gettext("Compare Selected")}
            </.link>
          </div>

          <div class="space-y-2">
            <label
              :for={candidate <- @candidates}
              class={[
                "flex items-center gap-3 p-3 rounded-lg border cursor-pointer transition-colors",
                candidate.id in @selected_ids && "bg-blue-50 border-blue-300",
                candidate.id not in @selected_ids && "hover:bg-gray-50"
              ]}
            >
              <input
                type="checkbox"
                checked={candidate.id in @selected_ids}
                phx-click="toggle_candidate"
                phx-value-id={candidate.id}
                class="w-4 h-4 text-blue-600"
                disabled={length(@selected_ids) >= 3 and candidate.id not in @selected_ids}
              />
              <div class="flex-1">
                <span class="font-medium">{candidate.name}</span>
                <span class="text-sm text-gray-500 ml-2">{candidate.email}</span>
              </div>
            </label>
          </div>
        </div>

        <div :if={@comparison_data} class="mt-8">
          <.link
            phx-click="clear_comparison"
            class="text-blue-600 hover:underline text-sm mb-6 inline-block"
          >
            {gettext("← Back to selection")}
          </.link>

          <div class="overflow-x-auto">
            <table class="w-full border-collapse text-sm">
              <thead>
                <tr>
                  <th class="text-left p-3 border bg-gray-50 w-48"></th>
                  <th
                    :for={item <- @comparison_data}
                    class="text-left p-3 border bg-gray-50 min-w-[250px]"
                  >
                    <div class="font-semibold">{item.candidate.name}</div>
                    <div class="text-xs text-gray-500">{item.candidate.email}</div>
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td class="p-3 border font-medium bg-gray-50">{gettext("Phone")}</td>
                  <td
                    :for={item <- @comparison_data}
                    class="p-3 border"
                  >
                    {item.candidate.phone || "—"}
                  </td>
                </tr>

                <tr>
                  <td class="p-3 border font-medium bg-gray-50">{gettext("LinkedIn")}</td>
                  <td
                    :for={item <- @comparison_data}
                    class="p-3 border"
                  >
                    <a
                      :if={item.candidate.linkedin_url}
                      href={item.candidate.linkedin_url}
                      target="_blank"
                      class="text-blue-600 hover:underline"
                    >
                      {gettext("Profile")}
                    </a>
                    <span :if={not item.candidate.linkedin_url}>—</span>
                  </td>
                </tr>

                <tr>
                  <td class="p-3 border font-medium bg-gray-50">{gettext("Applications")}</td>
                  <td
                    :for={item <- @comparison_data}
                    class="p-3 border"
                  >
                    <div :for={app <- item.applications} class="text-xs">
                      <span class="font-medium">{app.job.title}</span>
                      <span class="text-gray-500"> →  {app.pipeline_stage.name}</span>
                    </div>
                    <span :if={item.applications == []}>—</span>
                  </td>
                </tr>

                <tr>
                  <td class="p-3 border font-medium bg-gray-50">{gettext("Notes")}</td>
                  <td
                    :for={item <- @comparison_data}
                    class="p-3 border"
                  >
                    <div :for={note <- Enum.take(item.notes, 3)} class="text-xs">
                      <span :if={note.rating} class="text-yellow-600">★{note.rating}</span>
                      <span class="text-gray-600">{String.slice(note.body || "", 0, 50)}</span>
                    </div>
                    <span :if={item.notes == []}>—</span>
                  </td>
                </tr>

                <tr>
                  <td class="p-3 border font-medium bg-gray-50">{gettext("Scorecards")}</td>
                  <td
                    :for={item <- @comparison_data}
                    class="p-3 border"
                  >
                    <div :for={sc <- item.scorecards} class="text-xs">
                      <span class="font-medium">{sc.interviewer && sc.interviewer.name}</span>
                      <span class="text-gray-500"> — </span>
                      <span :if={sc.total_score} class="text-blue-600 font-semibold">
                        {sc.total_score}%
                      </span>
                      <span
                        :if={sc.recommendation}
                        class={[
                          "ml-2 px-2 py-0.5 rounded text-xs",
                          sc.recommendation == "strong_hire" && "bg-green-100 text-green-800",
                          sc.recommendation == "hire" && "bg-green-50 text-green-700",
                          sc.recommendation == "neutral" && "bg-gray-100 text-gray-700",
                          sc.recommendation == "no_hire" && "bg-red-50 text-red-700",
                          sc.recommendation == "strong_no_hire" && "bg-red-100 text-red-800"
                        ]}
                      >
                        {sc.recommendation}
                      </span>
                    </div>
                    <span :if={item.scorecards == []}>—</span>
                  </td>
                </tr>

                <tr :if={has_custom_fields?(@comparison_data)}>
                  <td class="p-3 border font-medium bg-gray-50">{gettext("Custom Fields")}</td>
                  <td
                    :for={item <- @comparison_data}
                    class="p-3 border"
                  >
                    <div :for={{key, value} <- item.custom_fields || %{}} class="text-xs">
                      <span class="text-gray-600">{key}:</span> {value}
                    </div>
                    <span :if={item.custom_fields == %{} or item.custom_fields == nil}>—</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("toggle_candidate", %{"id" => id}, socket) do
    id = String.to_integer(id)
    selected = socket.assigns.selected_ids

    selected =
      if id in selected do
        List.delete(selected, id)
      else
        if length(selected) < 3 do
          [id | selected]
        else
          selected
        end
      end

    {:noreply,
     socket
     |> assign(selected_ids: selected)
     |> assign(error: nil)}
  end

  def handle_event("compare", _params, socket) do
    case Comparison.compare_candidates(socket.assigns.selected_ids) do
      {:ok, data} ->
        {:noreply, assign(socket, comparison_data: data)}

      {:error, reason} ->
        {:noreply, assign(socket, error: reason)}
    end
  end

  def handle_event("clear_comparison", _params, socket) do
    {:noreply, assign(socket, comparison_data: nil)}
  end

  defp has_custom_fields?(comparison_data) do
    Enum.any?(comparison_data, fn item ->
      item.custom_fields != %{} and item.custom_fields != nil
    end)
  end
end
