defmodule TrebyWeb.Storybook.Patterns.PageHeader do
  use PhoenixStorybook.Story, :component

  def function, do: &TrebyWeb.DesignSystem.Pattern.page_header/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{title: "Users", subtitle: "Manage user accounts"},
        slots: [~s|<:actions><button class="btn btn-primary btn-sm">Add User</button></:actions>|]
      },
      %Variation{
        id: :with_breadcrumbs,
        attributes: %{
          title: "Candidate Details",
          subtitle: "View and manage candidate",
          breadcrumbs: [%{label: "Home", href: "/"}, %{label: "Candidates", href: "/candidates"}, %{label: "John Doe"}]
        },
        slots: [~s|<:actions><button class="btn btn-ghost btn-sm">Edit</button><button class="btn btn-primary btn-sm">Save</button></:actions>|]
      },
      %Variation{id: :title_only, attributes: %{title: "Settings"}},
      %Variation{
        id: :long_title,
        attributes: %{
          title: "Analytics — Pipeline Conversion Over Time",
          subtitle: "Track how candidates move through each stage"
        }
      }
    ]
  end
end
