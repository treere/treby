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
  def primary_classes, do: "btn btn-primary"

  @doc """
  Returns Tailwind classes for a button variant name.
  """
  def variant_classes("primary"), do: "btn btn-primary"
  def variant_classes("secondary"), do: "btn btn-secondary"
  def variant_classes("danger"), do: "btn btn-error"
  def variant_classes("ghost"), do: "btn btn-ghost"
  def variant_classes("outline"), do: "btn btn-outline"

  @doc """
  Returns Tailwind classes for a badge variant.
  """
  def badge_classes("default"), do: "badge"
  def badge_classes("success"), do: "badge badge-success"
  def badge_classes("warning"), do: "badge badge-warning"
  def badge_classes("danger"), do: "badge badge-error"
  def badge_classes("info"), do: "badge badge-info"

  @doc """
  Returns size modifier classes for buttons and inputs.
  """
  def size_classes("sm"), do: "btn-sm"
  def size_classes("md"), do: ""
  def size_classes("lg"), do: "btn-lg"
end
