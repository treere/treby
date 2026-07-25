defmodule Treby.EmailTemplates.EmailTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "email_templates" do
    field :name, :string
    field :stage_type, :string
    field :subject, :string
    field :body, :string
    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end

  def changeset(email_template, attrs) do
    email_template
    |> cast(attrs, [:name, :stage_type, :subject, :body])
    |> validate_required([:name, :stage_type, :subject, :body])
    |> validate_inclusion(:stage_type, ~w(rejected hired))
    |> unique_constraint([:stage_type, :tenant_id])
  end
end
