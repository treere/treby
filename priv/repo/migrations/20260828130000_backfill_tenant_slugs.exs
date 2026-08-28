defmodule Treby.Repo.Migrations.BackfillTenantSlugs do
  use Ecto.Migration

  import Ecto.Query

  alias Treby.Repo
  alias Treby.Tenants.Tenant

  def up do
    Tenant
    |> where([t], is_nil(t.slug) or t.slug == "")
    |> order_by([t], asc: t.inserted_at)
    |> Repo.all()
    |> Enum.each(fn tenant ->
      slug = unique_slug(tenant.name, 1)

      Repo.update_all(
        from(t in Tenant, where: t.id == ^tenant.id),
        set: [slug: slug]
      )
    end)
  end

  def down, do: :ok

  defp unique_slug(name, attempt) do
    base = slugify(name)
    candidate = if attempt == 1, do: base, else: "#{base}-#{attempt}"

    if Repo.get_by(Tenant, slug: candidate) do
      unique_slug(name, attempt + 1)
    else
      candidate
    end
  end

  defp slugify(name) do
    base =
      (name || "")
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, "-")
      |> String.trim("-")

    if base == "", do: "company", else: base
  end
end
