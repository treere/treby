defmodule TrebyWeb.ScorecardForm do
  use Phoenix.Component
  use Gettext, backend: TrebyWeb.Gettext

  import TrebyWeb.CoreComponents, only: [icon: 1]
  import TrebyWeb.DesignSystem.Button, only: [button: 1]

  attr :show, :boolean, default: false
  attr :criteria, :list, default: []
  attr :form, Phoenix.HTML.Form, required: true

  def scorecard_form(assigns) do
    ~H"""
    <div
      :if={@show}
      class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
    >
      <div class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm-xl max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
        <div class="p-6">
          <div class="flex justify-between items-center mb-4">
            <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
              {gettext("Scorecard")}
            </h2>
            <button
              phx-click="close_scorecard"
              class="text-zinc-500 dark:text-zinc-400 hover:text-zinc-500 dark:text-zinc-400"
            >
              <.icon name="hero-x-mark" class="w-6 h-6" />
            </button>
          </div>

          <.form
            for={@form}
            id="scorecard-form"
            phx-submit="submit_scorecard"
            class="space-y-4"
          >
            <div :for={criterion <- @criteria} class="space-y-1">
              <label class="block text-sm font-medium text-zinc-900 dark:text-zinc-100/80">
                {criterion["name"]}
              </label>
              <%= cond do %>
                <% criterion["type"] == "number_1_5" -> %>
                  <div class="flex gap-1">
                    <%= for n <- 1..5 do %>
                      <label class="cursor-pointer">
                        <input
                          type="radio"
                          name={criterion["name"]}
                          value={n}
                          checked={@form[criterion["name"]].value == to_string(n)}
                          class="sr-only peer"
                        />
                        <span class="text-2xl peer-checked:text-yellow-500 text-zinc-900 dark:text-zinc-100/30 hover:text-yellow-400">
                          ★
                        </span>
                      </label>
                    <% end %>
                  </div>
                <% criterion["type"] == "yes_no_maybe" -> %>
                  <select
                    name={criterion["name"]}
                    class="w-full rounded-lg border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-3 py-2 text-sm text-zinc-900 dark:text-zinc-100 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-orange-500"
                  >
                    <option value="" selected={@form[criterion["name"]].value == ""}>
                      Select...
                    </option>
                    <option
                      value="yes"
                      selected={@form[criterion["name"]].value == "yes"}
                    >
                      Yes
                    </option>
                    <option value="no" selected={@form[criterion["name"]].value == "no"}>
                      No
                    </option>
                    <option
                      value="maybe"
                      selected={@form[criterion["name"]].value == "maybe"}
                    >
                      Maybe
                    </option>
                  </select>
                <% true -> %>
                  <textarea
                    name={criterion["name"]}
                    rows="2"
                    class="w-full rounded-lg border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-3 py-2 text-sm text-zinc-900 dark:text-zinc-100 placeholder:text-zinc-400 dark:placeholder:text-zinc-400 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-orange-500"
                  >{@form[criterion["name"]].value}</textarea>
              <% end %>
            </div>

            <div class="space-y-1">
              <label class="block text-sm font-medium text-zinc-900 dark:text-zinc-100/80">
                {gettext("Recommendation")}
              </label>
              <select
                name="recommendation"
                class="w-full rounded-lg border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-3 py-2 text-sm text-zinc-900 dark:text-zinc-100 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-orange-500"
              >
                <option value="" selected={@form[:recommendation].value == ""}>
                  Select...
                </option>
                <option value="hire" selected={@form[:recommendation].value == "hire"}>
                  Strong Hire
                </option>
                <option
                  value="lean_hire"
                  selected={@form[:recommendation].value == "lean_hire"}
                >
                  Hire
                </option>
                <option
                  value="lean_no_hire"
                  selected={@form[:recommendation].value == "lean_no_hire"}
                >
                  Lean No
                </option>
                <option
                  value="no_hire"
                  selected={@form[:recommendation].value == "no_hire"}
                >
                  No Hire
                </option>
                <option
                  value="strong_no_hire"
                  selected={@form[:recommendation].value == "strong_no_hire"}
                >
                  Strong No Hire
                </option>
              </select>
            </div>

            <div class="space-y-1">
              <label class="block text-sm font-medium text-zinc-900 dark:text-zinc-100/80">{gettext(
                "Notes"
              )}</label>
              <textarea
                name="notes"
                rows="3"
                class="w-full rounded-lg border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-3 py-2 text-sm text-zinc-900 dark:text-zinc-100 placeholder:text-zinc-400 dark:placeholder:text-zinc-400 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-orange-500"
              >{@form[:notes].value}</textarea>
            </div>

            <div class="flex gap-2 justify-end">
              <.button type="button" phx-click="close_scorecard" variant="ghost">
                Cancel
              </.button>
              <.button type="submit" variant="primary">{gettext("Submit Scorecard")}</.button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end
