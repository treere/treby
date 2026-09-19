defmodule Treby.Availability.AvailabilityRule do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: [version: 7, precision: :monotonic]}
  @foreign_key_type :binary_id

  schema "availability_rules" do
    field :day_of_week, :integer
    field :start_time, :time
    field :end_time, :time
    field :scope, :string, default: "user"

    belongs_to :user, Treby.Accounts.User
    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end

  def changeset(rule, attrs) do
    rule
    |> cast(attrs, [:day_of_week, :start_time, :end_time, :scope, :user_id, :tenant_id])
    |> validate_required([:day_of_week, :start_time, :end_time, :scope, :tenant_id])
    |> validate_inclusion(:day_of_week, 0..6)
    |> validate_inclusion(:scope, ~w(company user))
    |> validate_user_id()
  end

  defp validate_user_id(%{changes: changes} = changeset) do
    scope = Map.get(changes, :scope) || get_field(changeset, :scope)

    required =
      if scope == "company" do
        [:day_of_week, :start_time, :end_time, :scope, :tenant_id]
      else
        [:day_of_week, :start_time, :end_time, :scope, :user_id, :tenant_id]
      end

    changeset
    |> validate_required(required)
    |> maybe_reject_user_id(scope)
  end

  defp maybe_reject_user_id(changeset, "company") do
    if get_change(changeset, :user_id) != nil do
      add_error(changeset, :user_id, "must be blank for company rules")
    else
      changeset
    end
  end

  defp maybe_reject_user_id(changeset, _scope), do: changeset
end
