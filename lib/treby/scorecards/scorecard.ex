defmodule Treby.Scorecards.Scorecard do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "scorecards" do
    field :scores, :map, default: %{}
    field :recommendation, :string
    field :notes, :string
    belongs_to :interview_event, Treby.Interviews.InterviewEvent
    belongs_to :interviewer, Treby.Accounts.User
    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end

  def changeset(scorecard, attrs) do
    scorecard
    |> cast(attrs, [
      :scores,
      :recommendation,
      :notes,
      :interview_event_id,
      :interviewer_id,
      :tenant_id
    ])
    |> validate_required([:interview_event_id, :interviewer_id, :tenant_id])
    |> validate_inclusion(:recommendation, ~w(hire lean_hire lean_no_hire no_hire strong_no_hire))
    |> unique_constraint([:interview_event_id, :interviewer_id])
  end
end
