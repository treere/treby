defmodule TrebyWeb.Storybook.Components.Card do
  use PhoenixStorybook.Story, :component

  def function, do: &TrebyWeb.DesignSystem.Card.card/1

  def variations do
    [
      %Variation{
        id: :default,
        slots: ["Simple card content"]
      },
      %Variation{
        id: :bordered,
        attributes: %{variant: "bordered"},
        slots: ["Bordered card"]
      },
      %Variation{
        id: :elevated,
        attributes: %{variant: "elevated"},
        slots: ["Elevated card"]
      },
      %Variation{
        id: :flat,
        attributes: %{variant: "flat"},
        slots: ["Flat card (transparent)"]
      },
      %Variation{
        id: :with_header_footer,
        attributes: %{variant: "default"},
        slots: [
          ~s|<:header>Card Header</:header>|,
          "Body content with header and footer",
          ~s|<:footer><button class="btn btn-primary btn-sm">Action</button></:footer>|
        ]
      },
      %Variation{
        id: :header_only,
        slots: [
          ~s|<:header>Only Header</:header>|,
          "Body below header"
        ]
      }
    ]
  end
end
