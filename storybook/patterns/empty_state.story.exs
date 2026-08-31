defmodule TrebyWeb.Storybook.Patterns.EmptyState do
  use PhoenixStorybook.Story, :component

  def function, do: &TrebyWeb.DesignSystem.Pattern.empty_state/1

  def variations do
    [
      %Variation{
        id: :no_users,
        attributes: %{
          icon: "hero-inbox",
          title: "No users yet",
          description: "Invite team members to get started."
        },
        slots: [~s|<:cta><a href="#" class="btn btn-primary">Invite Users</a></:cta>|]
      },
      %Variation{
        id: :no_candidates,
        attributes: %{
          icon: "hero-users",
          title: "No candidates",
          description: "Import or add candidates to see them here.",
          action: %{href: "#", label: "Add Candidate"}
        }
      },
      %Variation{
        id: :no_jobs,
        attributes: %{
          icon: "hero-briefcase",
          title: "No jobs posted",
          description: "Create your first job to start hiring.",
          actions: [%{href: "#", label: "Create Job"}, %{href: "#", label: "Import"}]
        }
      },
      %Variation{
        id: :no_interviews,
        attributes: %{
          icon: "hero-calendar",
          title: "No interviews scheduled",
          description: "Interviews will appear here once scheduled."
        }
      }
    ]
  end
end
