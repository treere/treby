defmodule TrebyWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The foundation for styling is Tailwind CSS, a utility-first CSS framework.
  Here are useful references:

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component
  use Gettext, backend: TrebyWeb.Gettext

  alias Phoenix.HTML.Form, as: HTMLForm
  alias Phoenix.LiveView.JS

  import TrebyWeb.DesignSystem.Badge, only: [badge: 1]

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash
        id="welcome-back"
        kind={:info}
        phx-mounted={show("#welcome-back") |> JS.remove_attribute("hidden")}
        hidden
      >
        Welcome Back!
      </.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="toast toast-top toast-end z-50"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
          <.icon name="hero-x-mark" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as radio, are best
  written directly in your templates.

  ## Examples

  ```heex
  <.input field={@form[:email]} type="email" />
  <.input name="my-input" errors={["oh no!"]} />
  ```

  ## Select type

  When using `type="select"`, you must pass the `options` and optionally
  a `value` to mark which option should be preselected.

  ```heex
  <.input field={@form[:user_type]} type="select" options={["Admin": "admin", "User": "user"]} />
  ```

  For more information on what kind of data can be passed to `options` see
  [`options_for_select`](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#options_for_select/2).
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week hidden)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :any, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :any, default: nil, doc: "the input error class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        HTMLForm.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <span class="label">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={
              @class ||
                "rounded border-zinc-300 dark:border-zinc-600 text-orange-600 focus:ring-orange-500 h-4 w-4"
            }
            {@rest}
          />{@label}
        </span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[
            @class ||
              "w-full rounded-lg border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-3 py-2 text-sm text-zinc-900 dark:text-zinc-100 focus:outline-none focus:ring-2 focus:ring-orange-500",
            @errors != [] && (@error_class || "select-error")
          ]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            @class ||
              "w-full rounded-lg border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-3 py-2 text-sm text-zinc-900 dark:text-zinc-100 placeholder:text-zinc-400 focus:outline-none focus:ring-2 focus:ring-orange-500",
            @errors != [] && (@error_class || "textarea-error")
          ]}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            @class ||
              "w-full rounded-lg border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-3 py-2 text-sm text-zinc-900 dark:text-zinc-100 placeholder:text-zinc-400 focus:outline-none focus:ring-2 focus:ring-orange-500",
            @errors != [] && (@error_class || "input-error")
          ]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex gap-2 items-center text-sm text-red-600 dark:text-red-400">
      <.icon name="hero-exclamation-circle" class="size-5" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-zinc-500 dark:text-zinc-400">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-hidden rounded-xl border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 shadow-sm">
      <table class="w-full">
        <thead class="bg-zinc-50 dark:bg-zinc-800 border-b border-zinc-200 dark:border-zinc-700">
          <tr>
            <th
              :for={col <- @col}
              class="px-4 py-3 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider"
            >
              {col[:label]}
            </th>
            <th :if={@action != []} class="px-4 py-3">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}
          class="divide-y divide-zinc-100 dark:divide-zinc-700"
        >
          <tr
            :for={row <- @rows}
            id={@row_id && @row_id.(row)}
            class="hover:bg-zinc-50 dark:hover:bg-zinc-700/50 transition-colors"
          >
            <td
              :for={col <- @col}
              phx-click={@row_click && @row_click.(row)}
              class={[
                "px-4 py-3 text-sm text-zinc-700 dark:text-zinc-300",
                @row_click && "hover:cursor-pointer"
              ]}
            >
              {render_slot(col, @row_item.(row))}
            </td>
            <td :if={@action != []} class="px-4 py-3 w-0 font-medium">
              <div class="flex gap-3">
                <%= for action <- @action do %>
                  {render_slot(action, @row_item.(row))}
                <% end %>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title={gettext("Title")}>{@post.title}</:item>
        <:item title={gettext("Views")}>{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div class="list-col-grow">
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(TrebyWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(TrebyWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  @doc """
  Renders an activity timeline showing recent events for an entity.
  """
  attr :events, :list, required: true

  def activity_timeline(assigns) do
    ~H"""
    <div class="space-y-3">
      <div :for={event <- @events} class="flex items-start gap-3">
        <div class={[
          "w-2 h-2 rounded-full mt-2 flex-shrink-0",
          event.action |> event_color()
        ]}>
        </div>
        <div class="flex-1 min-w-0">
          <p class="text-sm text-zinc-900 dark:text-zinc-100/90">{format_event(event)}</p>
          <p class="text-xs text-zinc-400 dark:text-zinc-500">{relative_time(event.inserted_at)}</p>
        </div>
      </div>
      <div :if={@events == []} class="text-sm text-zinc-400 dark:text-zinc-500">
        No activity yet.
      </div>
    </div>
    """
  end

  def candidate_card_info(assigns) do
    ~H"""
    <div>
      <div class="flex items-center justify-between gap-2">
        <.link
          navigate={@profile_link}
          class="font-medium text-sm text-zinc-900 dark:text-zinc-100 hover:text-blue-600 truncate"
        >
          {@name}
        </.link>
        <div class="flex items-center gap-1 flex-shrink-0">
          <.badge :if={not @reviewed} variant="danger" class="text-[10px]">NEW</.badge>
          <.badge :if={@is_duplicate} variant="warning" class="text-[10px]">DUPLICATE</.badge>
        </div>
      </div>
      <p class="text-xs text-zinc-400 dark:text-zinc-500 truncate">{@email}</p>
      <p :if={@other_positions} class="mt-1 text-[11px] text-blue-700">{@other_positions}</p>
      <%= case @upcoming_interview do %>
        <% [next_interview | _] -> %>
          <div class="mt-1 flex items-center gap-1 text-[11px] text-green-700 dark:text-green-100 bg-green-50 dark:bg-green-950 rounded px-2 py-1">
            <.icon name="hero-video-camera" class="w-3 h-3" />
            <span>{Elixir.Calendar.strftime(next_interview.start_at_utc, "%b %d %H:%M")}</span>
          </div>
        <% _ -> %>
      <% end %>
    </div>
    """
  end

  defp event_color("application_stage_changed"), do: "bg-blue-500"
  defp event_color("note_created"), do: "bg-yellow-500"
  defp event_color("interview_scheduled"), do: "bg-purple-500"
  defp event_color("interview_cancelled"), do: "bg-red-500"
  defp event_color("candidate_created"), do: "bg-green-500"
  defp event_color("candidate_updated"), do: "bg-zinc-200 dark:bg-zinc-700"
  defp event_color(_), do: "bg-zinc-200 dark:bg-zinc-700"

  defp format_event(%{action: "application_stage_changed", metadata: meta}) do
    gettext("Moved from %{old} to %{new}",
      old: meta["old_stage"] || "—",
      new: meta["new_stage"] || "—"
    )
  end

  defp format_event(%{action: "note_created"}), do: gettext("Added a note")
  defp format_event(%{action: "interview_scheduled"}), do: gettext("Interview scheduled")
  defp format_event(%{action: "interview_cancelled"}), do: gettext("Interview cancelled")
  defp format_event(%{action: "candidate_created"}), do: gettext("Candidate created")
  defp format_event(%{action: "candidate_updated"}), do: gettext("Candidate updated")

  defp format_event(%{action: "candidates_merged"}),
    do: gettext("Merged a duplicate profile into this candidate")

  defp format_event(%{action: "candidates_merge_undone"}),
    do: gettext("Undid a profile merge")

  defp format_event(%{action: action}),
    do: String.replace(action, "_", " ") |> String.capitalize()

  defp relative_time(dt) do
    diff = DateTime.diff(DateTime.utc_now(), dt, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86_400 -> "#{div(diff, 3600)}h ago"
      diff < 604_800 -> "#{div(diff, 86400)}d ago"
      true -> Calendar.strftime(dt, "%b %d, %Y")
    end
  end

  @doc """
  Renders an onboarding checklist for new users.
  """
  attr :steps, :list, required: true
  attr :current_user, :map, required: true
  attr :show, :boolean, default: true

  def onboarding_checklist(assigns) do
    done = Enum.count(assigns.steps, & &1.done)
    total = length(assigns.steps)
    assigns = assign(assigns, done: done, total: total, all_done: done == total)

    ~H"""
    <div
      :if={@show && !@all_done}
      id="onboarding-checklist"
      class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm border border-zinc-200 dark:border-zinc-700 p-6 mb-8"
    >
      <div class="flex items-center justify-between mb-4">
        <div class="flex items-center gap-3">
          <div class="rounded-full bg-blue-100 p-2">
            <.icon name="hero-rocket-launch" class="h-5 w-5 text-blue-600" />
          </div>
          <div>
            <h3 class="text-base font-semibold text-zinc-900 dark:text-zinc-100">
              {gettext("Get Started with Treby")}
            </h3>
            <p class="text-xs text-zinc-400 dark:text-zinc-500">{@done} of {@total} steps complete</p>
          </div>
        </div>
        <button
          type="button"
          phx-click="dismiss-onboarding"
          phx-value-dismiss="session"
          class="text-zinc-400 dark:text-zinc-500 hover:text-zinc-500 dark:text-zinc-400 transition-colors"
          aria-label={gettext("Dismiss checklist")}
        >
          <.icon name="hero-x-mark" class="h-5 w-5" />
        </button>
      </div>

      <div class="space-y-3 mb-4">
        <div :for={step <- @steps}>
          <.link
            navigate={step.href}
            class={[
              "flex items-center gap-3 rounded-lg px-3 py-2.5 transition-colors group",
              step.done && "bg-green-50 dark:bg-green-900/30",
              !step.done && "hover:bg-zinc-50 dark:bg-zinc-800"
            ]}
          >
            <div class={[
              "flex-shrink-0 h-5 w-5 rounded-full border-2 flex items-center justify-center transition-colors",
              step.done && "bg-green-500 border-green-500",
              !step.done && "border-zinc-200 dark:border-zinc-700 group-hover:border-blue-400"
            ]}>
              <.icon
                :if={step.done}
                name="hero-check"
                class="h-3 w-3 text-white"
              />
            </div>
            <span class={[
              "text-sm transition-colors",
              step.done && "text-zinc-400 dark:text-zinc-500 line-through",
              !step.done && "text-zinc-900 dark:text-zinc-100/80 group-hover:text-blue-600"
            ]}>
              {step.label}
            </span>
            <.icon
              :if={!step.done}
              name="hero-arrow-right"
              class="h-4 w-4 text-zinc-900 dark:text-zinc-100/30 group-hover:text-blue-400 ml-auto transition-colors"
            />
          </.link>
        </div>
      </div>

      <div class="flex items-center justify-between">
        <div class="flex-1 mr-4">
          <div class="h-2 bg-zinc-50 dark:bg-zinc-800 rounded-full overflow-hidden">
            <div
              class="h-full bg-blue-500 rounded-full transition-all duration-500"
              style={"width: #{if @total > 0, do: div(@done * 100, @total), else: 0}%"}
            >
            </div>
          </div>
        </div>
        <button
          type="button"
          phx-click="dismiss-onboarding"
          phx-value-dismiss="permanent"
          class="text-xs text-zinc-400 dark:text-zinc-500 hover:text-zinc-500 dark:text-zinc-400 transition-colors whitespace-nowrap"
        >
          Don't show again
        </button>
      </div>
    </div>
    """
  end
end
