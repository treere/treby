defmodule TrebyWeb.ComparisonLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Comparison}

  def mount(%{"ids" => ids} = _params, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])

    selected_ids = ids |> String.split(",", trim: true) |> Enum.map(&String.trim/1)

    {comparison_data, error} =
      case Comparison.compare_candidates(selected_ids) do
        {:ok, data} -> {data, nil}
        {:error, reason} -> {nil, reason}
      end

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(selected_ids: selected_ids)
     |> assign(comparison_data: comparison_data)
     |> assign(error: error)}
  end

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(selected_ids: [])
     |> assign(comparison_data: nil)
     |> assign(error: gettext("Select 2-3 candidates from the list to compare them"))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <div class="flex items-center justify-between mb-6">
          <h1 class="text-2xl font-bold">{gettext("Compare Candidates")}</h1>
          <.link
            navigate={~p"/app/candidates"}
            class="text-blue-600 hover:underline text-sm"
          >
            {gettext("← Back to candidates")}
          </.link>
        </div>

        <div :if={@error} class="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700">
          {@error}
        </div>

        <div :if={@comparison_data} class="overflow-x-auto">
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
                  <span :if={is_nil(item.candidate.linkedin_url)}>—</span>
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
                    <span class="text-gray-500">
                      <span aria-hidden="true">→</span>{app.pipeline_stage.name}
                    </span>
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
                    <span class="text-gray-600">{String.slice(note.content || "", 0, 50)}</span>
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
    </Layouts.app>
    """
  end

  defp has_custom_fields?(comparison_data) do
    Enum.any?(comparison_data, fn item ->
      item.custom_fields != %{} and item.custom_fields != nil
    end)
  end
end
