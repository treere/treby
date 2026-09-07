defmodule TrebyWeb.Storybook.Components.Pagination do
  use PhoenixStorybook.Story, :component

  def function, do: &TrebyWeb.DesignSystem.Pagination.pagination/1

  def variations do
    [
      %Variation{
        id: :middle_page,
        attributes: %{page: 5, total_pages: 10, total_count: 243, page_size: 25}
      },
      %Variation{
        id: :first_page,
        attributes: %{page: 1, total_pages: 10, total_count: 243, page_size: 25}
      },
      %Variation{
        id: :last_page,
        attributes: %{page: 10, total_pages: 10, total_count: 243, page_size: 25}
      },
      %Variation{
        id: :single_page,
        attributes: %{page: 1, total_pages: 1, total_count: 7, page_size: 25}
      },
      %Variation{
        id: :empty,
        attributes: %{page: 1, total_pages: 1, total_count: 0, page_size: 25}
      }
    ]
  end
end
