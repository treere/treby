defmodule Treby.Candidates.Candidate do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: [version: 7, precision: :monotonic]}
  @foreign_key_type :binary_id

  schema "candidates" do
    field :name, :string
    field :email, :string
    field :phone, :string
    field :linkedin_url, :string
    field :custom_fields, :map, default: %{}
    field :notification_preferences, :map, default: %{}
    field :merged_at, :utc_datetime

    belongs_to :tenant, Treby.Tenants.Tenant
    has_many :applications, Treby.Pipeline.Application

    belongs_to :merged_into, Treby.Candidates.Candidate, foreign_key: :merged_into_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(candidate, attrs) do
    candidate
    |> cast(attrs, [
      :name,
      :email,
      :phone,
      :linkedin_url,
      :custom_fields,
      :notification_preferences
    ])
    |> update_change(:email, &normalize_email/1)
    |> validate_required([:name, :email])
    |> Treby.Emails.validate_format(:email)
    |> unique_constraint(:email, name: :candidates_tenant_email_unique_active)
  end

  defp normalize_email(email) when is_binary(email), do: String.trim(email)
  defp normalize_email(email), do: email
end
