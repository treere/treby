defmodule Treby.CandidatePortal.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_sender_types ~w(recruiter candidate system)
  @valid_message_types ~w(text request_info rejection status_update interview_invite offer)

  schema "messages" do
    field :sender_type, :string
    field :sender_id, :binary_id
    field :body, :string
    field :message_type, :string, default: "text"
    field :metadata, :map, default: %{}

    belongs_to :conversation, Treby.CandidatePortal.Conversation

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:sender_type, :sender_id, :body, :message_type, :metadata, :conversation_id])
    |> validate_required([:sender_type, :body, :message_type, :conversation_id])
    |> validate_inclusion(:sender_type, @valid_sender_types)
    |> validate_inclusion(:message_type, @valid_message_types)
  end
end
