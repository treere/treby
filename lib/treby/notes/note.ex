defmodule Treby.Notes.Note do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "notes" do
    field :content, :string
    field :type, :string, default: "note"
    field :rating, :integer

    belongs_to :tenant, Treby.Tenants.Tenant
    belongs_to :application, Treby.Pipeline.Application
    belongs_to :author, Treby.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:content, :type, :rating, :tenant_id, :application_id, :author_id])
    |> validate_required([:content, :application_id, :author_id])
    |> validate_inclusion(:type, ~w(note feedback interview_feedback))
    |> validate_number(:rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
  end
end
