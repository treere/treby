defmodule Treby.DataPrivacy.DataPrivacyRequest do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: [version: 7, precision: :monotonic]}
  @foreign_key_type :binary_id

  @types ~w(export erasure)
  @scopes ~w(user tenant)
  @statuses ~w(pending processing ready expired completed cancelled failed)

  schema "data_privacy_requests" do
    field :type, :string
    field :scope, :string
    field :status, :string, default: "pending"
    field :s3_key, :string
    field :expires_at, :utc_datetime
    field :completed_at, :utc_datetime
    field :metadata, :map, default: %{}
    field :error, :string

    belongs_to :tenant, Treby.Tenants.Tenant
    belongs_to :requester, Treby.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(request, attrs) do
    request
    |> cast(attrs, [
      :tenant_id,
      :requester_id,
      :type,
      :scope,
      :status,
      :s3_key,
      :expires_at,
      :completed_at,
      :metadata,
      :error
    ])
    |> validate_required([:tenant_id, :requester_id, :type, :scope, :status])
    |> validate_inclusion(:type, @types)
    |> validate_inclusion(:scope, @scopes)
    |> validate_inclusion(:status, @statuses)
    |> validate_s3_key_for_type()
    |> foreign_key_constraint(:tenant_id)
    |> foreign_key_constraint(:requester_id)
    |> unique_constraint([:tenant_id, :type, :scope, :requester_id],
      name: :data_privacy_requests_pending_unique,
      message: "already has a pending request of this type"
    )
  end

  defp validate_s3_key_for_type(changeset) do
    type = get_field(changeset, :type)
    s3_key = get_field(changeset, :s3_key)

    if type == "erasure" and not is_nil(s3_key) do
      add_error(changeset, :s3_key, "must be nil for erasure")
    else
      changeset
    end
  end

  def expired?(%__MODULE__{expires_at: nil}), do: false

  def expired?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) != :lt
  end
end
