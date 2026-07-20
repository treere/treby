defmodule Treby.Repo.Migrations.MakeBookingTokenInterviewerNullable do
  use Ecto.Migration

  def change do
    alter table(:booking_tokens) do
      modify :interviewer_id, :binary_id, null: true
    end
  end
end
