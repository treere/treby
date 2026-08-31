defmodule TrebyWeb.Storybook.Components.Toast do
  use PhoenixStorybook.Story, :component

  def function, do: &TrebyWeb.DesignSystem.Feedback.toast/1

  def variations do
    [
      %Variation{id: :info, attributes: %{kind: :info}, slots: ["Job saved successfully"]},
      %Variation{
        id: :info_with_title,
        attributes: %{kind: :info, title: "Updated"},
        slots: ["Job saved successfully"]
      },
      %Variation{
        id: :success,
        attributes: %{kind: :success, title: "Success"},
        slots: ["Profile updated"]
      },
      %Variation{id: :success_no_title, attributes: %{kind: :success}, slots: ["Done"]},
      %Variation{
        id: :warning,
        attributes: %{kind: :warning, title: "Warning"},
        slots: ["Please review your input"]
      },
      %Variation{id: :error, attributes: %{kind: :error}, slots: ["Something went wrong"]},
      %Variation{
        id: :error_with_title,
        attributes: %{kind: :error, title: "Failed"},
        slots: ["Could not save changes"]
      }
    ]
  end
end
