defmodule Treby.Tenants do
  @moduledoc """
  The Tenants context.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Tenants.Tenant

  def list_tenants do
    Repo.all(Tenant)
  end

  def get_tenant!(id), do: Repo.get!(Tenant, id)

  def get_tenant_by_slug!(slug) do
    Repo.get_by!(Tenant, slug: slug)
  end

  def get_tenant_by_slug(slug), do: Repo.get_by(Tenant, slug: slug)

  def create_tenant(attrs \\ %{}) do
    %Tenant{}
    |> Tenant.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, tenant} ->
        # Create default pipeline stages for the new tenant
        Treby.Pipeline.create_default_pipeline_stages(tenant)
        {:ok, tenant}

      error ->
        error
    end
  end

  def update_tenant(%Tenant{} = tenant, attrs) do
    tenant
    |> Tenant.changeset(attrs)
    |> Repo.update()
  end

  def delete_tenant(%Tenant{} = tenant) do
    Repo.delete(tenant)
  end

  def change_tenant(%Tenant{} = tenant, attrs \\ %{}) do
    Tenant.changeset(tenant, attrs)
  end
end
