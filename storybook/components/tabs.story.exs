defmodule TrebyWeb.Storybook.Components.Tabs do
  use PhoenixStorybook.Story, :component

  def function, do: &TrebyWeb.DesignSystem.Tabs.tabs/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          id: "demo-tabs",
          tabs: [
            %{key: "active", label: "Active", count: 5},
            %{key: "archived", label: "Archived"},
            %{key: "all", label: "All", count: 12}
          ],
          active_tab: "active"
        },
        slots: ["<p class=\"p-4\">Active tab content</p>"]
      },
      %Variation{
        id: :no_counts,
        attributes: %{
          id: "demo-tabs-nocount",
          tabs: [
            %{key: "one", label: "One"},
            %{key: "two", label: "Two"},
            %{key: "three", label: "Three"}
          ],
          active_tab: "two"
        }
      },
      %Variation{
        id: :first_active,
        attributes: %{
          id: "demo-tabs-first",
          tabs: [
            %{key: "a", label: "Alpha"},
            %{key: "b", label: "Beta"}
          ],
          active_tab: "a"
        }
      }
    ]
  end
end
