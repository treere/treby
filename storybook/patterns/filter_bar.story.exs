defmodule TrebyWeb.Storybook.Patterns.FilterBar do
  use PhoenixStorybook.Story, :component

  def function, do: &TrebyWeb.DesignSystem.Pattern.filter_bar/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          id: "demo-filter",
          fields: [
            %{key: "status", label: "Status", type: "text", value: "", placeholder: "Filter by status"},
            %{key: "search", label: "Search", type: "text", value: "", placeholder: "Search..."}
          ],
          on_change: "filter",
          on_reset: "reset_filters"
        }
      },
      %Variation{
        id: :with_values,
        attributes: %{
          id: "demo-filter-filled",
          fields: [
            %{key: "q", label: "Search", type: "text", value: "john", placeholder: "Search..."},
            %{key: "stage", label: "Stage", type: "text", value: "screening", placeholder: "Stage"}
          ]
        }
      },
      %Variation{
        id: :single_field,
        attributes: %{
          id: "demo-filter-single",
          fields: [%{key: "query", label: "Query", type: "text", value: "", placeholder: "Type to filter"}]
        }
      }
    ]
  end
end
