defmodule Treby.ScheduledMessages.ScheduledMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_statuses ~w(scheduled sent failed cancelled)

  schema "scheduled_messages" do
    field :sender_type, :string
    field :sender_id, :binary_id
    field :body, :string
    field :message_type, :string, default: "text"
    field :metadata, :map, default: %{}
    field :send_at, :utc_datetime
    field :status, :string, default: "scheduled"
    field :sent_at, :utc_datetime
    field :failed_at, :utc_datetime
    field :error_reason, :string
    field :retry_count, :integer, default: 0
    field :created_by_id, :binary_id

    belongs_to :conversation, Treby.CandidatePortal.Conversation
    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(scheduled_message, attrs) do
    scheduled_message
    |> cast(attrs, [
      :sender_type,
      :sender_id,
      :body,
      :message_type,
      :metadata,
      :send_at,
      :status,
      :sent_at,
      :failed_at,
      :error_reason,
      :retry_count,
      :created_by_id,
      :conversation_id,
      :tenant_id
    ])
    |> validate_required([:body, :send_at, :conversation_id, :tenant_id])
    |> validate_inclusion(:status, @valid_statuses)
  end
end
