defmodule Treby.EmailQueue.ScheduledEmail do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "scheduled_emails" do
    field :status, :string, default: "scheduled"
    field :scheduled_at, :utc_datetime
    field :send_at, :utc_datetime
    field :jitter_minutes, :integer, default: 0

    field :to_address, :string
    field :from_address, :string
    field :subject, :string
    field :body, :string
    field :html_body, :string

    field :email_type, :string
    field :reference_type, :string
    field :reference_id, :binary_id

    field :sent_at, :utc_datetime
    field :failed_at, :utc_datetime
    field :error_reason, :string
    field :retry_count, :integer, default: 0

    belongs_to :tenant, Treby.Tenants.Tenant
    belongs_to :created_by, Treby.Accounts.User
    belongs_to :thread, Treby.EmailThreads.EmailThread
    belongs_to :email_message, Treby.EmailThreads.EmailMessage

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(scheduled_email, attrs) do
    scheduled_email
    |> cast(attrs, [
      :tenant_id,
      :created_by_id,
      :status,
      :scheduled_at,
      :send_at,
      :jitter_minutes,
      :to_address,
      :from_address,
      :subject,
      :body,
      :html_body,
      :email_type,
      :reference_type,
      :reference_id,
      :thread_id,
      :email_message_id,
      :sent_at,
      :failed_at,
      :error_reason,
      :retry_count
    ])
    |> validate_required([
      :tenant_id,
      :status,
      :scheduled_at,
      :send_at,
      :to_address,
      :from_address,
      :subject,
      :email_type
    ])
    |> validate_inclusion(:status, ["scheduled", "sending", "sent", "failed", "cancelled"])
    |> validate_inclusion(:email_type, ["compose", "reply", "bulk", "stage_change"])
  end
end
