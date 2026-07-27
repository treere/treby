defmodule Treby.Careers do
  @moduledoc """
  The Careers context - public career page functionality.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Careers.CareerPage

  def get_career_page_by_tenant(tenant_id) do
    Repo.get_by(CareerPage, tenant_id: tenant_id)
  end

  def get_published_career_page_by_tenant(tenant_id) do
    CareerPage
    |> where([cp], cp.tenant_id == ^tenant_id and cp.published == true)
    |> Repo.one()
  end

  def create_career_page(attrs \\ %{}) do
    %CareerPage{}
    |> CareerPage.changeset(attrs)
    |> Repo.insert()
  end

  def update_career_page(%CareerPage{} = career_page, attrs) do
    career_page
    |> CareerPage.changeset(attrs)
    |> Repo.update()
  end

  def change_career_page(%CareerPage{} = career_page, attrs \\ %{}) do
    CareerPage.changeset(career_page, attrs)
  end

  def has_branding?(tenant_id) do
    CareerPage
    |> where([cp], cp.tenant_id == ^tenant_id)
    |> Repo.exists?()
  end
end
