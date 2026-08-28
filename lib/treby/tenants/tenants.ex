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
    attrs = ensure_slug(attrs)

    %Tenant{}
    |> Tenant.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, tenant} ->
        # Set default notification preferences
        settings =
          Map.put(tenant.settings || %{}, "notifications", %{
            "stage_change_candidate" => true,
            "new_application_candidate" => true,
            "new_application_team" => true,
            "interview_reminder" => true
          })

        {:ok, tenant} = tenant |> Tenant.changeset(%{settings: settings}) |> Repo.update()

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

  defp ensure_slug(attrs) do
    if Map.has_key?(attrs, :slug) || Map.has_key?(attrs, "slug") do
      attrs
    else
      name = Map.get(attrs, :name) || Map.get(attrs, "name") || ""

      if name == "" do
        attrs
      else
        Map.put(attrs, :slug, generate_unique_slug(name))
      end
    end
  end

  def generate_unique_slug(name) do
    base =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, "-")
      |> String.trim("-")

    base = if base == "", do: "company", else: base
    find_unique_slug(base, 1)
  end

  defp find_unique_slug(base, attempt) do
    candidate = if attempt == 1, do: base, else: "#{base}-#{attempt}"

    if Repo.get_by(Tenant, slug: candidate) do
      find_unique_slug(base, attempt + 1)
    else
      candidate
    end
  end
end
