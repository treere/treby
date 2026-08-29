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
    field :provider_event_id, :string
    field :calendar_provider, :string
    field :calendar_owner_id, :binary_id
    field :status, :string, default: "scheduled"
    field :notes, :string

    belongs_to :scheduled_by, Treby.Accounts.User
    belongs_to :application, Treby.Pipeline.Application
    belongs_to :tenant, Treby.Tenants.Tenant

    has_many :event_examiners, Treby.Interviews.EventExaminer
    has_many :examiners, through: [:event_examiners, :user]
    has_many :scorecards, Treby.Scorecards.Scorecard

    timestamps(type: :utc_datetime)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :start_at_utc,
      :end_at_utc,
      :duration_minutes,
      :video_conf_url,
      :provider_event_id,
      :calendar_provider,
      :calendar_owner_id,
      :status,
      :notes,
      :scheduled_by_id,
      :application_id,
      :tenant_id
    ])
    |> validate_required([
      :start_at_utc,
      :end_at_utc,
      :duration_minutes,
      :application_id,
      :tenant_id
    ])
    |> validate_inclusion(:status, ~w(scheduled completed cancelled))
    |> validate_number(:duration_minutes, greater_than: 0)
  end
end
