defmodule TrebyWeb.Storybook.Components.Button do
  use PhoenixStorybook.Story, :component

  def function, do: &TrebyWeb.DesignSystem.Button.button/1

  def variations do
    [
      %Variation{
        id: :primary,
        attributes: %{variant: "primary"},
        slots: ["Primary"]
      },
      %Variation{
        id: :secondary,
        attributes: %{variant: "secondary"},
        slots: ["Secondary"]
      },
      %Variation{
        id: :danger,
        attributes: %{variant: "danger"},
        slots: ["Danger"]
      },
      %Variation{
        id: :ghost,
        attributes: %{variant: "ghost"},
        slots: ["Ghost"]
      },
      %Variation{
        id: :outline,
        attributes: %{variant: "outline"},
        slots: ["Outline"]
      },
      %Variation{
        id: :small,
        attributes: %{variant: "primary", size: "sm"},
        slots: ["Small"]
      },
      %Variation{
        id: :large,
        attributes: %{variant: "primary", size: "lg"},
        slots: ["Large"]
      },
      %Variation{
        id: :loading,
        attributes: %{variant: "primary", loading: true},
        slots: ["Loading"]
      },
      %Variation{
        id: :disabled,
        attributes: %{variant: "primary", disabled: true},
        slots: ["Disabled"]
      },
      %Variation{
        id: :as_link,
        attributes: %{variant: "primary", navigate: "/"},
        slots: ["As Link"]
      }
    ]
  end
end
