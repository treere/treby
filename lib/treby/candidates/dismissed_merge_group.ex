defmodule Treby.Candidates.DismissedMergeGroup do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "dismissed_merge_groups" do
    field :group_key, :string
    field :dismissed_at, :utc_datetime

    belongs_to :tenant, Treby.Tenants.Tenant
    belongs_to :dismissed_by, Treby.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(dismissed_merge_group, attrs) do
    dismissed_merge_group
    |> cast(attrs, [:tenant_id, :group_key, :dismissed_by_id, :dismissed_at])
    |> validate_required([:tenant_id, :group_key, :dismissed_at])
    |> unique_constraint([:tenant_id, :group_key])
  end
end
