defmodule Treby.AI.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: [version: 7, precision: :monotonic]}
  @foreign_key_type :binary_id

  schema "ai_conversations" do
    field :title, :string
    field :status, :string, default: "active"

    belongs_to :tenant, Treby.Tenants.Tenant
    belongs_to :user, Treby.Accounts.User
    has_many :messages, Treby.AI.Message

    timestamps(type: :utc_datetime)
  end

  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:tenant_id, :user_id, :title, :status])
    |> validate_required([:tenant_id, :user_id])
  end
end
