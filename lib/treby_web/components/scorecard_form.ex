defmodule TrebyWeb.ScorecardForm do
  use Phoenix.Component
  use Gettext, backend: TrebyWeb.Gettext

  import TrebyWeb.CoreComponents, only: [input: 1]
  import TrebyWeb.DesignSystem.Button, only: [button: 1]
  import TrebyWeb.DesignSystem.Modal, only: [modal: 1]

  attr :show, :boolean, default: false
  attr :criteria, :list, default: []
  attr :form, Phoenix.HTML.Form, required: true

  def scorecard_form(assigns) do
    ~H"""
    <.modal
      id="scorecard-modal"
      show={@show}
      title={gettext("Scorecard")}
      size="lg"
      close_event="close_scorecard"
    >
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
              <.input
                type="select"
                name={criterion["name"]}
                value={@form[criterion["name"]].value}
                options={[{"Select...", ""}, {"Yes", "yes"}, {"No", "no"}, {"Maybe", "maybe"}]}
              />
            <% true -> %>
              <.input
                type="textarea"
                name={criterion["name"]}
                value={@form[criterion["name"]].value}
                rows="2"
              />
          <% end %>
        </div>

        <.input
          type="select"
          name="recommendation"
          label={gettext("Recommendation")}
          value={@form[:recommendation].value}
          options={[
            {"Select...", ""},
            {"Strong Hire", "hire"},
            {"Hire", "lean_hire"},
            {"Lean No", "lean_no_hire"},
            {"No Hire", "no_hire"},
            {"Strong No Hire", "strong_no_hire"}
          ]}
        />

        <.input
          type="textarea"
          name="notes"
          label={gettext("Notes")}
          value={@form[:notes].value}
          rows="3"
        />

        <div class="flex gap-2 justify-end">
          <.button type="submit" variant="primary" loading_text={gettext("Submitting...")}>{gettext(
            "Submit Scorecard"
          )}</.button>
        </div>
      </.form>
      <:footer>
        <.button type="button" phx-click="close_scorecard" variant="ghost">
          Cancel
        </.button>
      </:footer>
    </.modal>
    """
  end
end
