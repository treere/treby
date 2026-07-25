defmodule Treby.Scorecards do
  @moduledoc """
  The Scorecards context — manages scorecard templates and filled scorecards.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Scorecards.ScorecardTemplate
  alias Treby.Scorecards.Scorecard

  def list_scorecard_templates(tenant_id) do
    ScorecardTemplate
    |> where([st], st.tenant_id == ^tenant_id)
    |> order_by([st], st.position)
    |> Repo.all()
  end

  def get_scorecard_template!(id), do: Repo.get!(ScorecardTemplate, id)

  def get_active_template(tenant_id) do
    ScorecardTemplate
    |> where([st], st.tenant_id == ^tenant_id)
    |> order_by([st], st.position)
    |> limit(1)
    |> Repo.one()
  end

  def create_scorecard_template(attrs \\ %{}, actor \\ nil) do
    if actor && actor.role != "admin" do
      {:error, :unauthorized}
    else
      %ScorecardTemplate{tenant_id: attrs["tenant_id"]}
      |> ScorecardTemplate.changeset(attrs)
      |> Repo.insert()
    end
  end

  def update_scorecard_template(%ScorecardTemplate{} = scorecard_template, attrs, actor \\ nil) do
    if actor && actor.role != "admin" do
      {:error, :unauthorized}
    else
      scorecard_template
      |> ScorecardTemplate.changeset(attrs)
      |> Repo.update()
    end
  end

  def delete_scorecard_template(%ScorecardTemplate{} = scorecard_template, actor \\ nil) do
    if actor && actor.role != "admin" do
      {:error, :unauthorized}
    else
      Repo.delete(scorecard_template)
    end
  end

  def change_scorecard_template(%ScorecardTemplate{} = scorecard_template, attrs \\ %{}) do
    ScorecardTemplate.changeset(scorecard_template, attrs)
  end

  def submit_scorecard(interview_event_id, interviewer_id, attrs) do
    case Repo.get_by(Scorecard,
           interview_event_id: interview_event_id,
           interviewer_id: interviewer_id
         ) do
      nil ->
        %Scorecard{}
        |> Scorecard.changeset(
          Map.merge(attrs, %{
            "interview_event_id" => interview_event_id,
            "interviewer_id" => interviewer_id
          })
        )
        |> Repo.insert()

      existing ->
        existing
        |> Scorecard.changeset(attrs)
        |> Repo.update()
    end
  end

  def get_scorecard_for_interview(interview_event_id, interviewer_id) do
    Repo.get_by(Scorecard, interview_event_id: interview_event_id, interviewer_id: interviewer_id)
  end

  def get_scorecard!(id), do: Repo.get!(Scorecard, id)

  def list_scorecards_for_candidate(candidate_id) do
    Scorecard
    |> join(:inner, [s], ie in Treby.Interviews.InterviewEvent, on: s.interview_event_id == ie.id)
    |> where([s, ie], ie.candidate_id == ^candidate_id)
    |> preload([s, ie], interviewer: [], interview_event: [])
    |> Repo.all()
  end

  def list_scorecards_for_interview(interview_event_id) do
    Scorecard
    |> where([s], s.interview_event_id == ^interview_event_id)
    |> preload([:interviewer])
    |> Repo.all()
  end

  def compute_aggregate_scores(candidate_id) do
    scorecards = list_scorecards_for_candidate(candidate_id)

    if scorecards == [] do
      %{
        avg_scores: %{},
        recommendation_counts: %{},
        total_scorecards: 0
      }
    else
      avg_scores =
        scorecards
        |> Enum.flat_map(fn sc -> Map.to_list(sc.scores || %{}) end)
        |> Enum.group_by(fn {key, _} -> key end)
        |> Enum.map(fn {key, entries} ->
          values = Enum.map(entries, fn {_, v} -> v end) |> Enum.filter(&is_number/1)
          avg = if values == [], do: 0, else: Enum.sum(values) / length(values)
          {key, avg}
        end)
        |> Map.new()

      recommendation_counts =
        scorecards
        |> Enum.map(& &1.recommendation)
        |> Enum.frequencies()

      %{
        avg_scores: avg_scores,
        recommendation_counts: recommendation_counts,
        total_scorecards: length(scorecards)
      }
    end
  end
end
