defmodule Treby.Careers.CareerPage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "career_pages" do
    field :title, :string
    field :description, :string
    field :logo_url, :string
    field :primary_color, :string, default: "#3b82f6"
    field :published, :boolean, default: false

    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(career_page, attrs) do
    career_page
    |> cast(attrs, [:title, :description, :logo_url, :primary_color, :published])
    |> validate_required([:title])
  end
end
