defmodule TrebyWeb.Storybook.Components.Modal do
  use PhoenixStorybook.Story, :component

  def function, do: &TrebyWeb.DesignSystem.Modal.modal/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{id: "demo-modal", show: true, title: "Example Modal"},
        slots: ["This is the modal body content."]
      },
      %Variation{
        id: :small,
        attributes: %{id: "demo-modal-sm", show: true, title: "Small Modal", size: "sm"},
        slots: ["Small modal content."]
      },
      %Variation{
        id: :large,
        attributes: %{id: "demo-modal-lg", show: true, title: "Large Modal", size: "lg"},
        slots: ["Large modal content with more space."]
      },
      %Variation{
        id: :xl,
        attributes: %{id: "demo-modal-xl", show: true, title: "XL Modal", size: "xl"},
        slots: ["Extra large modal."]
      },
      %Variation{
        id: :with_footer,
        attributes: %{id: "demo-modal-footer", show: true, title: "Modal with Footer"},
        slots: [
          "Modal body with footer actions.",
          ~s|<:footer><button class="btn">Cancel</button><button class="btn btn-primary">Confirm</button></:footer>|
        ]
      },
      %Variation{
        id: :hidden,
        attributes: %{id: "demo-modal-hidden", show: false, title: "Hidden Modal"},
        slots: ["You should not see this when show is false."]
      }
    ]
  end
end
