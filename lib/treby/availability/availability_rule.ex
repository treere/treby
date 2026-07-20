defmodule Treby.Availability.AvailabilityRule do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "availability_rules" do
    field :day_of_week, :integer
    field :start_time, :time
    field :end_time, :time
    field :timezone, :string, default: "UTC"
    field :buffer_before, :integer, default: 15
    field :buffer_after, :integer, default: 15

    belongs_to :user, Treby.Accounts.User
    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end

  def changeset(rule, attrs) do
    rule
    |> cast(attrs, [
      :day_of_week,
      :start_time,
      :end_time,
      :timezone,
      :buffer_before,
      :buffer_after,
      :user_id,
      :tenant_id
    ])
    |> validate_required([:day_of_week, :start_time, :end_time, :timezone, :user_id, :tenant_id])
    |> validate_inclusion(:day_of_week, 0..6)
    |> validate_number(:buffer_before, greater_than_or_equal_to: 0)
    |> validate_number(:buffer_after, greater_than_or_equal_to: 0)
    |> unique_constraint([:tenant_id, :user_id, :day_of_week])
  end
end
