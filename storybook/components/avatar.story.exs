defmodule TrebyWeb.Storybook.Components.Avatar do
  use PhoenixStorybook.Story, :component

  def function, do: &TrebyWeb.DesignSystem.Avatar.avatar/1

  def variations do
    [
      %Variation{
        id: :initials_md,
        attributes: %{initials: "JD", size: "md"}
      },
      %Variation{id: :initials_xs, attributes: %{initials: "AB", size: "xs"}},
      %Variation{id: :initials_sm, attributes: %{initials: "AB", size: "sm"}},
      %Variation{id: :initials_lg, attributes: %{initials: "JD", size: "lg"}},
      %Variation{id: :initials_xl, attributes: %{initials: "JD", size: "xl"}},
      %Variation{
        id: :with_image,
        attributes: %{
          src: "https://i.pravatar.cc/100",
          alt: "User avatar",
          size: "md"
        }
      },
      %Variation{
        id: :image_large,
        attributes: %{src: "https://i.pravatar.cc/150", alt: "Large avatar", size: "lg"}
      }
    ]
  end
end
