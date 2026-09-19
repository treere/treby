defmodule Treby.Repo.Migrations.BackfillTenantSlugs do
  use Ecto.Migration

  import Ecto.Query

  alias Treby.Repo

  def up do
    from(t in "tenants",
      where: is_nil(t.slug) or t.slug == "",
      order_by: [asc: t.inserted_at],
      select: %{id: t.id, name: t.name, slug: t.slug}
    )
    |> Repo.all()
    |> Enum.each(fn tenant ->
      slug = unique_slug(tenant.name, 1)

      Repo.update_all(
        from(t in "tenants", where: t.id == ^tenant.id),
        set: [slug: slug]
      )
    end)
  end

  def down, do: :ok

  defp unique_slug(name, attempt) do
    base = slugify(name)
    candidate = if attempt == 1, do: base, else: "#{base}-#{attempt}"

    if Repo.exists?(from(t in "tenants", where: t.slug == ^candidate)) do
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
