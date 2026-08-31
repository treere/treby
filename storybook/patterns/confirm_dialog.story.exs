defmodule TrebyWeb.Storybook.Patterns.ConfirmDialog do
  use PhoenixStorybook.Story, :component

  def function, do: &TrebyWeb.DesignSystem.Pattern.confirm_dialog/1

  def variations do
    [
      %Variation{
        id: :danger,
        attributes: %{
          id: "confirm-demo-danger",
          show: true,
          title: "Delete user?",
          message: "This permanently removes the user and all associated data.",
          confirm_label: "Delete",
          confirm_variant: "danger",
          on_confirm: "delete_user"
        }
      },
      %Variation{
        id: :primary,
        attributes: %{
          id: "confirm-demo-primary",
          show: true,
          title: "Confirm action?",
          message: "Are you sure you want to proceed?",
          confirm_label: "Confirm",
          confirm_variant: "primary",
          on_confirm: "confirm_action"
        }
      },
      %Variation{
        id: :hidden,
        attributes: %{
          id: "confirm-demo-hidden",
          show: false,
          title: "Hidden dialog",
          message: "You should not see this"
        }
      },
      %Variation{
        id: :with_extra_attrs,
        attributes: %{
          id: "confirm-demo-extra",
          show: true,
          title: "Delete candidate?",
          message: "Delete John Doe? This cannot be undone.",
          confirm_label: "Delete",
          confirm_variant: "danger",
          on_confirm: "delete_candidate",
          extra_attrs: %{id: 42}
        }
      }
    ]
  end
end
