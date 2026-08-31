defmodule TrebyWeb.Storybook.Components.Skeleton do
  use PhoenixStorybook.Story, :component

  def function, do: &TrebyWeb.DesignSystem.Feedback.skeleton/1

  def variations do
    [
      %Variation{id: :text_default, attributes: %{variant: "text"}},
      %Variation{id: :text_half, attributes: %{variant: "text", width: "w-1/2"}},
      %Variation{id: :text_three_quarters, attributes: %{variant: "text", width: "w-3/4"}},
      %Variation{id: :avatar, attributes: %{variant: "avatar"}},
      %Variation{id: :card_one_line, attributes: %{variant: "card", lines: 1}},
      %Variation{id: :card_three_lines, attributes: %{variant: "card", lines: 3}},
      %Variation{id: :card_five_lines, attributes: %{variant: "card", lines: 5}}
    ]
  end
end
