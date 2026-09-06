defmodule TrebyWeb.DesignSystem do
  @moduledoc """
  Design system for Treby — reusable UI components and style helpers.

  All components follow Phoenix.Component conventions with `attr` declarations
  and `slot` definitions. Each component accepts a `class` assign for additional
  Tailwind classes and `:rest` for HTML attribute pass-through.

  ## Available components

  ### Core
    - `<.Button>` — Button with variants, sizes, loading, icon support
    - `<.Badge>` — Status badge with color variants
    - `<.Card>` — Content card with header/body/footer slots
    - `<.Modal>` — Dialog modal with backdrop and keyboard dismiss
    - `<.Dropdown>` — Popover menu with trigger
    - `<.Tabs>` — Tab navigation (controlled/uncontrolled)
    - `<.Spinner>` — Loading spinner
    - `<.Skeleton>` — Content placeholder skeleton
    - `<.Avatar>` — User avatar with image or initials

  ### Patterns
    - `<.ConfirmDialog>` — Confirmation modal for destructive actions
    - `<.PageHeader>` — Page title with breadcrumbs and actions
    - `<.EmptyState>` — Empty state with icon and CTA
    - `<.FilterBar>` — Filter controls with apply/reset
    - `<.FormSection>` — Grouped form fields with title
    - `<.LoadingOverlay>` — Dimmed overlay with spinner
  """

  @doc """
  Returns Tailwind classes for the primary variant.
  """
  def primary_classes,
    do:
      "bg-orange-600 text-white hover:bg-orange-700 border border-orange-600 focus-visible:ring-orange-600"

  @doc """
  Returns Tailwind classes for a button variant name.
  """
  def variant_classes("primary"),
    do:
      "bg-orange-600 text-white hover:bg-orange-700 border border-orange-600 focus-visible:ring-orange-600"

  def variant_classes("secondary"),
    do:
      "bg-white text-zinc-900 hover:bg-zinc-50 border border-zinc-200 focus-visible:ring-zinc-900 dark:bg-zinc-800 dark:text-zinc-100 dark:border-zinc-700 dark:hover:bg-zinc-700"

  def variant_classes("danger"),
    do: "bg-red-600 text-white hover:bg-red-700 border border-red-600 focus-visible:ring-red-600"

  def variant_classes("ghost"),
    do:
      "bg-transparent text-zinc-600 hover:bg-zinc-100 hover:text-zinc-900 border border-transparent shadow-none focus-visible:ring-zinc-400 dark:text-zinc-300 dark:hover:bg-zinc-800 dark:hover:text-zinc-100"

  def variant_classes("outline"),
    do:
      "bg-white text-zinc-700 hover:bg-zinc-50 border border-zinc-300 focus-visible:ring-zinc-400 dark:bg-zinc-800 dark:text-zinc-200 dark:border-zinc-600 dark:hover:bg-zinc-700"

  @doc """
  Returns Tailwind classes for a badge variant.
  """
  def badge_classes("default"),
    do:
      "inline-flex items-center rounded-full border text-xs font-medium bg-zinc-100 text-zinc-700 border-zinc-200 dark:bg-zinc-700 dark:text-zinc-200 dark:border-zinc-600"

  def badge_classes("success"),
    do:
      "inline-flex items-center rounded-full border text-xs font-medium bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-950 dark:text-emerald-200 dark:border-emerald-800"

  def badge_classes("warning"),
    do:
      "inline-flex items-center rounded-full border text-xs font-medium bg-amber-50 text-amber-700 border-amber-200 dark:bg-amber-950 dark:text-amber-200 dark:border-amber-800"

  def badge_classes("danger"),
    do:
      "inline-flex items-center rounded-full border text-xs font-medium bg-red-50 text-red-700 border-red-200 dark:bg-red-950 dark:text-red-200 dark:border-red-800"

  def badge_classes("info"),
    do:
      "inline-flex items-center rounded-full border text-xs font-medium bg-blue-50 text-blue-700 border-blue-200 dark:bg-blue-950 dark:text-blue-200 dark:border-blue-800"

  @doc """
  Returns size modifier classes for buttons and inputs.
  """
  def size_classes("sm"), do: "h-8 px-3 text-xs"
  def size_classes("md"), do: "h-9 px-4 text-sm"
  def size_classes("lg"), do: "h-10 px-6 text-base"

  @doc """
  Returns theme-aware classes for form controls (input/select/textarea)
  using the SaaS minimal tokens. Use this instead of bare `input`/`select`
  DaisyUI classes to ensure dark-mode contrast.
  """
  def input_classes(extra \\ "")

  def input_classes(extra) when is_binary(extra) do
    base =
      "w-full rounded-lg border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-3 py-2 text-sm text-zinc-900 dark:text-zinc-100 placeholder:text-zinc-400 dark:placeholder:text-zinc-400 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-orange-500"

    if extra == "", do: base, else: base <> " " <> extra
  end

  def select_classes(extra \\ "") do
    input_classes(extra)
  end

  def textarea_classes(extra \\ "") do
    input_classes(extra)
  end

  @doc """
  Returns theme-aware tab classes for the active/inactive states.
  """
  def tab_classes(:active_primary),
    do: "border-primary text-primary dark:text-orange-300 dark:border-orange-300"

  def tab_classes(:active_error),
    do: "border-red-600 text-red-600 dark:text-red-400 dark:border-red-400"

  def tab_classes(:inactive),
    do:
      "border-transparent text-zinc-500 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100 hover:border-zinc-200 dark:hover:border-zinc-700"

  @doc """
  Typography helpers — single source for headings and muted text so all fonts
  remain legible in both light and dark mode.
  """
  def typography_classes(:h1),
    do: "text-2xl font-bold text-zinc-900 dark:text-zinc-100"

  def typography_classes(:h2),
    do: "text-xl font-bold text-zinc-900 dark:text-zinc-100"

  def typography_classes(:h3),
    do: "text-lg font-semibold text-zinc-900 dark:text-zinc-100"

  def typography_classes(:h4),
    do: "text-base font-semibold text-zinc-900 dark:text-zinc-100"

  def typography_classes(:subtitle),
    do: "text-sm text-zinc-500 dark:text-zinc-400"

  def typography_classes(:body),
    do: "text-sm text-zinc-900 dark:text-zinc-100"

  def typography_classes(:caption),
    do: "text-xs text-zinc-500 dark:text-zinc-400"
end
