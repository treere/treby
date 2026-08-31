defmodule TrebyWeb.Storybook.Components.Badge do
  use PhoenixStorybook.Story, :component

  def function, do: &TrebyWeb.DesignSystem.Badge.badge/1

  def variations do
    [
      %Variation{id: :default, slots: ["Default"]},
      %Variation{id: :success, attributes: %{variant: "success"}, slots: ["Success"]},
      %Variation{id: :warning, attributes: %{variant: "warning"}, slots: ["Warning"]},
      %Variation{id: :danger, attributes: %{variant: "danger"}, slots: ["Danger"]},
      %Variation{id: :info, attributes: %{variant: "info"}, slots: ["Info"]},
      %Variation{id: :with_dot, attributes: %{variant: "success", dot: true}, slots: ["With dot"]}
    ]
  end
end
