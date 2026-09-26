defmodule TrebyWeb.DesignSystem.Badge do
  use Phoenix.Component

  import TrebyWeb.DesignSystem, only: [badge_classes: 1, status_variant: 1]

  attr :variant, :string,
    values: ~w(default success warning danger info),
    default: "default"

  attr :dot, :boolean, default: false, doc: "shows a colored dot indicator"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block

  @doc ~S'''
  Renders a badge with color variant and optional dot indicator.

  ## Examples

      <.badge>Active</.badge>
      <.badge variant="success" dot>Verified</.badge>
      <.badge variant="danger">Expired</.badge>

  Variants: `default`, `success`, `warning`, `danger`, `info`
  '''
  def badge(assigns) do
    ~H"""
    <span class={[badge_classes(@variant), "px-2.5 py-0.5", @class]} {@rest}>
      <span
        :if={@dot}
        class={[
          "inline-block size-1.5 rounded-full mr-1",
          @variant == "default" && "bg-zinc-500",
          @variant == "success" && "bg-emerald-600",
          @variant == "warning" && "bg-amber-500",
          @variant == "danger" && "bg-red-600",
          @variant == "info" && "bg-blue-600"
        ]}
      />
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr :status, :any, required: true, doc: "domain status string/atom mapped via status_variant/1"
  attr :label, :string, default: nil, doc: "override label, defaults to status"
  attr :dot, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global

  @doc ~S'''
  Renders a status badge with centralized status-to-variant mapping.

  ## Examples

      <.status_badge status="hired" />
      <.status_badge status={@job.status} />
      <.status_badge status="rejected" label="Not selected" />

  Uses `TrebyWeb.DesignSystem.status_variant/1`; no per-screen `case` maps.
  '''
  def status_badge(assigns) do
    assigns =
      assigns
      |> assign_new(:label, fn -> to_string(assigns.status) end)
      |> assign(:variant, status_variant(assigns.status))

    ~H"""
    <.badge variant={@variant} dot={@dot} class={@class} {@rest}>
      {@label}
    </.badge>
    """
  end
end
