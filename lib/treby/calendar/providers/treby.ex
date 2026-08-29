defmodule Treby.Calendar.Providers.Treby do
  @moduledoc """
  Internal calendar provider: busy periods come from the user's already
  scheduled interviews on Treby. Always active.
  """

  import Ecto.Query
  alias Treby.Repo
  alias Treby.Interviews.EventExaminer
  alias Treby.Interviews.InterviewEvent

  @doc """
  Returns the user's scheduled interviews overlapping the time range as busy
  periods. Never errors.
  """
  def fetch_busy(user_id, time_min, time_max) do
    periods =
      InterviewEvent
      |> join(:inner, [e], ee in EventExaminer, on: ee.interview_event_id == e.id)
      |> where([e, ee], ee.user_id == ^user_id and ee.status == "scheduled")
      |> where([e], e.status == "scheduled")
      |> where([e], e.start_at_utc < ^time_max and e.end_at_utc > ^time_min)
      |> select([e], %{start: e.start_at_utc, end: e.end_at_utc})
      |> Repo.all()

    {:ok, periods}
  end
end
