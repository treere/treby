defmodule Treby.EmailThreads.EmailThread do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "email_threads" do
    field :subject, :string
    field :last_message_at, :utc_datetime

    belongs_to :candidate, Treby.Candidates.Candidate
    belongs_to :tenant, Treby.Tenants.Tenant
    has_many :messages, Treby.EmailThreads.EmailMessage, foreign_key: :thread_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(thread, attrs) do
    thread
    |> cast(attrs, [:subject, :candidate_id, :tenant_id, :last_message_at])
    |> validate_required([:subject, :candidate_id, :tenant_id, :last_message_at])
  end
end
