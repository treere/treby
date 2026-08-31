defmodule TrebyWeb.Storybook.Components.Dropdown do
  use PhoenixStorybook.Story, :component

  def function, do: &TrebyWeb.DesignSystem.Dropdown.dropdown/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{id: "demo-dropdown"},
        slots: [
          ~s|<:trigger><button class="btn btn-ghost">Actions</button></:trigger>|,
          ~s|<:item><a> Edit</a></:item>|,
          ~s|<:item><a> Delete</a></:item>|
        ]
      },
      %Variation{
        id: :align_end,
        attributes: %{id: "demo-dropdown-end", align: "end"},
        slots: [
          ~s|<:trigger><button class="btn btn-primary">Menu (end)</button></:trigger>|,
          ~s|<:item><a> Profile</a></:item>|,
          ~s|<:item><a> Settings</a></:item>|,
          ~s|<:item><a> Logout</a></:item>|
        ]
      }
    ]
  end
end
