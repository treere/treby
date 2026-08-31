defmodule Treby.Jobs.Job do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "jobs" do
    field :title, :string
    field :description, :string
    field :salary_range, :string
    field :status, :string, default: "open"
    field :visible, :boolean, default: true
    field :custom_fields, :map, default: %{}
    field :location, :string
    field :employment_type, :string
    field :workplace_type, :string

    belongs_to :tenant, Treby.Tenants.Tenant
    belongs_to :pipeline, Treby.Pipeline.Pipeline

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(job, attrs) do
    job
    |> cast(attrs, [
      :title,
      :description,
      :salary_range,
      :status,
      :visible,
      :custom_fields,
      :pipeline_id,
      :location,
      :employment_type,
      :workplace_type
    ])
    |> validate_required([:title, :description])
    |> validate_inclusion(:status, ~w(open closed))
    |> validate_employment_type()
    |> validate_workplace_type()
  end

  defp validate_employment_type(changeset) do
    case get_field(changeset, :employment_type) do
      nil -> changeset
      "" -> changeset
      value when value in ~w(full_time part_time contract internship) -> changeset
      _ -> add_error(changeset, :employment_type, "is invalid")
    end
  end

  defp validate_workplace_type(changeset) do
    case get_field(changeset, :workplace_type) do
      nil -> changeset
      "" -> changeset
      value when value in ~w(on_site hybrid remote) -> changeset
      _ -> add_error(changeset, :workplace_type, "is invalid")
    end
  end

  def employment_type_label("full_time"), do: "Full-time"
  def employment_type_label("part_time"), do: "Part-time"
  def employment_type_label("contract"), do: "Contract"
  def employment_type_label("internship"), do: "Internship"
  def employment_type_label(_), do: nil

  def workplace_type_label("on_site"), do: "On-site"
  def workplace_type_label("hybrid"), do: "Hybrid"
  def workplace_type_label("remote"), do: "Remote"
  def workplace_type_label(_), do: nil
end
