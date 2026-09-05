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
      "bg-white text-zinc-900 hover:bg-zinc-50 border border-zinc-200 focus-visible:ring-zinc-900"

  def variant_classes("danger"),
    do: "bg-red-600 text-white hover:bg-red-700 border border-red-600 focus-visible:ring-red-600"

  def variant_classes("ghost"),
    do:
      "bg-transparent text-zinc-600 hover:bg-zinc-100 hover:text-zinc-900 border border-transparent shadow-none focus-visible:ring-zinc-400"

  def variant_classes("outline"),
    do:
      "bg-white text-zinc-700 hover:bg-zinc-50 border border-zinc-300 focus-visible:ring-zinc-400"

  @doc """
  Returns Tailwind classes for a badge variant.
  """
  def badge_classes("default"),
    do:
      "inline-flex items-center rounded-full border text-xs font-medium bg-zinc-100 text-zinc-700 border-zinc-200"

  def badge_classes("success"),
    do:
      "inline-flex items-center rounded-full border text-xs font-medium bg-emerald-50 text-emerald-700 border-emerald-200"

  def badge_classes("warning"),
    do:
      "inline-flex items-center rounded-full border text-xs font-medium bg-amber-50 text-amber-700 border-amber-200"

  def badge_classes("danger"),
    do:
      "inline-flex items-center rounded-full border text-xs font-medium bg-red-50 text-red-700 border-red-200"

  def badge_classes("info"),
    do:
      "inline-flex items-center rounded-full border text-xs font-medium bg-blue-50 text-blue-700 border-blue-200"

  @doc """
  Returns size modifier classes for buttons and inputs.
  """
  def size_classes("sm"), do: "h-8 px-3 text-xs"
  def size_classes("md"), do: "h-9 px-4 text-sm"
  def size_classes("lg"), do: "h-10 px-6 text-base"
end
