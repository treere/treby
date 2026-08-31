defmodule TrebyWeb.Storybook.Patterns.LoadingOverlay do
  use PhoenixStorybook.Story, :component

  def function, do: &TrebyWeb.DesignSystem.Pattern.loading_overlay/1

  def variations do
    [
      %Variation{
        id: :not_loading,
        attributes: %{loading: false, label: "Loading..."},
        slots: ["<div class=\"p-8 bg-base-100 border rounded\">Content that is not loading</div>"]
      },
      %Variation{
        id: :loading,
        attributes: %{loading: true, label: "Syncing data..."},
        slots: ["<div class=\"p-8 bg-base-100 border rounded\">Content that will be dimmed during loading</div>"]
      },
      %Variation{
        id: :loading_custom_label,
        attributes: %{loading: true, label: "Saving branding..."},
        slots: ["<div class=\"p-8 bg-base-100 border rounded\">Saving...</div>"]
      }
    ]
  end
end
