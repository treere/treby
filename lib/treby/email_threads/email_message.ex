defmodule Treby.EmailThreads.EmailMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "email_messages" do
    field :direction, :string
    field :from_address, :string
    field :to_address, :string
    field :subject, :string
    field :body, :string
    field :html_body, :string
    field :sent_at, :utc_datetime
    field :received_at, :utc_datetime

    belongs_to :thread, Treby.EmailThreads.EmailThread

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [
      :direction,
      :from_address,
      :to_address,
      :subject,
      :body,
      :html_body,
      :sent_at,
      :received_at,
      :thread_id
    ])
    |> validate_required([:direction, :from_address, :to_address, :body, :thread_id])
    |> validate_inclusion(:direction, ["inbound", "outbound"])
  end
end
