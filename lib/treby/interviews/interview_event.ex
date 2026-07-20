defmodule Treby.Interviews.InterviewEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "interview_events" do
    field :start_at_utc, :utc_datetime
    field :end_at_utc, :utc_datetime
    field :duration_minutes, :integer
    field :video_conf_url, :string
    field :google_event_id, :string
    field :status, :string, default: "scheduled"
    field :notes, :string

    belongs_to :scheduled_by, Treby.Accounts.User
    belongs_to :interviewer, Treby.Accounts.User
    belongs_to :application, Treby.Pipeline.Application
    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :start_at_utc,
      :end_at_utc,
      :duration_minutes,
      :video_conf_url,
      :google_event_id,
      :status,
      :notes,
      :scheduled_by_id,
      :interviewer_id,
      :application_id,
      :tenant_id
    ])
    |> validate_required([
      :start_at_utc,
      :end_at_utc,
      :duration_minutes,
      :interviewer_id,
      :application_id,
      :tenant_id
    ])
    |> validate_inclusion(:status, ~w(scheduled completed cancelled))
    |> validate_number(:duration_minutes, greater_than: 0)
    |> unique_constraint([:interviewer_id, :start_at_utc],
      name: "unique_scheduled_interview_per_interviewer_slot",
      message: "This time slot is no longer available"
    )
  end
end
