defmodule Treby.Comparison do
  import Ecto.Query, warn: false
  alias Treby.Repo

  def compare_candidates(candidate_ids)
      when length(candidate_ids) < 2 or length(candidate_ids) > 3 do
    {:error, "Select 2-3 candidates to compare"}
  end

  def compare_candidates(candidate_ids) do
    alias Treby.Candidates.Candidate
    alias Treby.Scorecards.Scorecard
    alias Treby.Activities.ActivityLog

    candidates =
      Candidate
      |> where([c], c.id in ^candidate_ids)
      |> Repo.all()
      |> Repo.preload([
        :tenant,
        applications: [:job, :pipeline_stage, notes: [:author]]
      ])

    # Get scorecards for these candidates
    interview_ids =
      candidates
      |> Enum.flat_map(& &1.applications)
      |> Enum.flat_map(fn app ->
        ActivityLog
        |> where(
          [a],
          a.action == "interview_scheduled" and a.entity_type == "application" and
            a.entity_id == ^app.id
        )
        |> select([a], a.id)
        |> Repo.all()
      end)

    scorecards =
      if interview_ids != [] do
        Scorecard
        |> where([s], s.interview_event_id in ^interview_ids)
        |> Repo.all()
        |> Repo.preload([:interviewer])
      else
        []
      end

    # Group scorecards by candidate
    scorecards_by_candidate =
      scorecards
      |> Enum.group_by(fn sc ->
        # Find the application for this scorecard's interview
        event = Repo.get!(ActivityLog, sc.interview_event_id)
        event.entity_id
      end)

    # Build comparison data
    comparison_data =
      Enum.map(candidates, fn candidate ->
        candidate_scorecards =
          candidate.applications
          |> Enum.flat_map(fn app -> Map.get(scorecards_by_candidate, app.id, []) end)

        all_notes =
          candidate.applications
          |> Enum.flat_map(fn app -> app.notes || [] end)

        %{
          candidate: candidate,
          applications: candidate.applications,
          notes: all_notes,
          scorecards: candidate_scorecards,
          custom_fields: candidate.custom_fields
        }
      end)

    {:ok, comparison_data}
  end
end
