defmodule TrebyWeb.Storybook.Patterns.FormSection do
  use PhoenixStorybook.Story, :component

  def function, do: &TrebyWeb.DesignSystem.Pattern.form_section/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{title: "Contact Information", description: "How to reach this candidate"},
        slots: ["<p class=\"text-sm\">Form fields would go here (email, phone, etc.)</p>"]
      },
      %Variation{
        id: :no_description,
        attributes: %{title: "Branding"},
        slots: ["<div class=\"space-y-2\"><div class=\"h-10 bg-base-200 rounded\"></div><div class=\"h-10 bg-base-200 rounded\"></div></div>"]
      },
      %Variation{
        id: :with_id,
        attributes: %{id: "section-demo", title: "Privacy", description: "Manage privacy settings"},
        slots: ["<p>Section with explicit id</p>"]
      }
    ]
  end
end
