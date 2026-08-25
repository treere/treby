defmodule Treby.Interviews.EventExaminer do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "interview_event_examiners" do
    field :status, :string, default: "scheduled"

    belongs_to :interview_event, Treby.Interviews.InterviewEvent
    belongs_to :user, Treby.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(event_examiner, attrs) do
    event_examiner
    |> cast(attrs, [:interview_event_id, :user_id, :status])
    |> validate_required([:interview_event_id, :user_id])
    |> validate_inclusion(:status, ~w(scheduled cancelled))
    |> unique_constraint([:interview_event_id, :user_id])
  end
end
