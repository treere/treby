defmodule Treby.CandidatePortal.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_contexts ~w(general application info_request rejection interview offer)
  @valid_statuses ~w(open waiting_candidate closed)

  schema "conversations" do
    field :subject, :string
    field :context, :string, default: "general"
    field :status, :string, default: "open"
    field :last_message_at, :utc_datetime

    belongs_to :candidate, Treby.Candidates.Candidate
    belongs_to :application, Treby.Pipeline.Application
    belongs_to :tenant, Treby.Tenants.Tenant
    has_many :messages, Treby.CandidatePortal.Message

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [
      :subject,
      :context,
      :status,
      :last_message_at,
      :candidate_id,
      :application_id,
      :tenant_id
    ])
    |> validate_required([:candidate_id, :tenant_id])
    |> validate_inclusion(:context, @valid_contexts)
    |> validate_inclusion(:status, @valid_statuses)
  end
end
