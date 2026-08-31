defmodule TrebyWeb.Storybook.Components.Spinner do
  use PhoenixStorybook.Story, :component

  def function, do: &TrebyWeb.DesignSystem.Feedback.spinner/1

  def variations do
    [
      %Variation{id: :default, attributes: %{size: "md"}},
      %Variation{id: :small, attributes: %{size: "sm"}},
      %Variation{id: :large, attributes: %{size: "lg"}},
      %Variation{
        id: :with_label,
        attributes: %{size: "md"},
        slots: ["Loading candidates..."]
      },
      %Variation{
        id: :large_with_label,
        attributes: %{size: "lg"},
        slots: ["Syncing data..."]
      }
    ]
  end
end
