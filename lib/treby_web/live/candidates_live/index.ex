defmodule TrebyWeb.CandidatesLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Candidates}
  alias Treby.Candidates.Candidate

  def mount(_params, session, socket) do
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])
    candidates = Candidates.list_candidates(tenant.id)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(candidates: candidates)
     |> assign(show_form: false)
     |> assign(form: to_form(Candidates.change_candidate(%Candidate{})))}
  end

  def render(assigns) do
    ~H"""
    <div class="p-8">
      <div class="flex justify-between items-center mb-8">
        <h1 class="text-2xl font-bold">Candidates</h1>
        <button
          phx-click="show_create_form"
          class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
        >
          + Add Candidate
        </button>
      </div>

      <div :if={@show_form} class="mb-8 p-6 bg-white rounded-lg shadow">
        <h2 class="text-lg font-semibold mb-4">Add Candidate</h2>
        <.form for={@form} id="candidate-form" phx-submit="create_candidate">
          <.input field={@form[:name]} type="text" label="Name" />
          <.input field={@form[:email]} type="email" label="Email" />
          <.input field={@form[:phone]} type="text" label="Phone" />
          <.input field={@form[:linkedin_url]} type="text" label="LinkedIn URL" />
          <div class="mt-4 flex gap-2">
            <.button type="submit">Add</.button>
            <.button type="button" phx-click="hide_create_form" class="bg-gray-500">Cancel</.button>
          </div>
        </.form>
      </div>

      <div class="bg-white rounded-lg shadow overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Name
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Email
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Phone
              </th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr :for={candidate <- @candidates} class="hover:bg-gray-50">
              <td class="px-6 py-4 whitespace-nowrap font-medium text-gray-900">{candidate.name}</td>
              <td class="px-6 py-4 whitespace-nowrap text-gray-600">{candidate.email}</td>
              <td class="px-6 py-4 whitespace-nowrap text-gray-600">{candidate.phone || "-"}</td>
              <td class="px-6 py-4 whitespace-nowrap text-sm">
                <button
                  phx-click="delete_candidate"
                  phx-value-candidate_id={candidate.id}
                  class="text-red-600 hover:text-red-900"
                >
                  Delete
                </button>
              </td>
            </tr>
          </tbody>
        </table>
        <div :if={@candidates == []} class="p-8 text-center text-gray-500">
          No candidates yet. Add your first candidate!
        </div>
      </div>
    </div>
    """
  end

  def handle_event("show_create_form", _, socket) do
    {:noreply, assign(socket, show_form: true)}
  end

  def handle_event("hide_create_form", _, socket) do
    {:noreply, assign(socket, show_form: false)}
  end

  def handle_event("create_candidate", %{"candidate" => candidate_params}, socket) do
    attrs = Map.put(candidate_params, "tenant_id", socket.assigns.current_tenant.id)

    case Candidates.create_candidate(attrs) do
      {:ok, _candidate} ->
        candidates = Candidates.list_candidates(socket.assigns.current_tenant.id)

        {:noreply,
         socket
         |> assign(candidates: candidates, show_form: false)
         |> assign(form: to_form(Candidates.change_candidate(%Candidate{})))
         |> put_flash(:info, "Candidate added")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("delete_candidate", %{"candidate_id" => candidate_id}, socket) do
    candidate = Candidates.get_candidate!(socket.assigns.current_tenant.id, candidate_id)
    :ok = Candidates.delete_candidate(candidate)
    candidates = Candidates.list_candidates(socket.assigns.current_tenant.id)
    {:noreply, assign(socket, candidates: candidates)}
  end
end
