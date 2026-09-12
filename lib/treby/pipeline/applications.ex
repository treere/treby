defmodule Treby.Pipeline.Applications do
  @moduledoc """
  Application lifecycle: listing, creation, progress, moves, and review state.

  Extracted from `Treby.Pipeline`. `Treby.Pipeline` remains the public facade.
  """

  import Ecto.Query, warn: false
  require Logger
  alias Treby.Candidates.Queries
  alias Treby.Repo
  alias Treby.Pipeline.PipelineStage
  alias Treby.Pipeline.Application
  alias Treby.Pipeline.Stages
  alias Treby.Interviews.InterviewEvent
  alias Treby.Helpers.Map, as: HelpersMap

  # Scorecard completion

  def all_scorecards_completed?(%Application{} = application) do
    stage = Repo.preload(application, [:pipeline_stage]).pipeline_stage

    if stage.stage_type != "interview" do
      true
    else
      interviews =
        InterviewEvent
        |> where([e], e.application_id == ^application.id)
        |> preload([:event_examiners])
        |> Repo.all()

      examiner_ids =
        interviews
        |> Enum.flat_map(&Enum.map(&1.event_examiners, fn ee -> ee.user_id end))
        |> Enum.uniq()

      if examiner_ids == [] do
        true
      else
        completed_count =
          interviews
          |> Enum.map(& &1.id)
          |> then(fn event_ids ->
            Treby.Scorecards.Scorecard
            |> where([s], s.interview_event_id in ^event_ids)
            |> where([s], s.interviewer_id in ^examiner_ids)
            |> select([s], count(s.id))
            |> Repo.one()
          end)

        completed_count >= length(examiner_ids)
      end
    end
  end

  @doc """
  Returns true when an application is ready to advance out of its interview stage:
  the interview has been marked completed AND all scorecards are submitted.
  """
  def ready_to_advance?(%Application{} = application) do
    stage = Repo.preload(application, [:pipeline_stage]).pipeline_stage

    if stage.stage_type != "interview" do
      true
    else
      interview_completed?(application) and all_scorecards_completed?(application)
    end
  end

  @doc """
  Returns true when every interview event for the application is completed,
  or when the application is not at the interview stage.
  """
  def interview_completed?(%Application{} = application) do
    stage = Repo.preload(application, [:pipeline_stage]).pipeline_stage

    if stage.stage_type != "interview" do
      true
    else
      not (InterviewEvent
           |> where([e], e.application_id == ^application.id and e.status != "completed")
           |> Repo.exists?())
    end
  end

  @doc """
  Computes the current progress state for an application.

  Returns a map with:
    - `:stage` — the current `PipelineStage`
    - `:blocked?` — whether advancement is blocked
    - `:blockers` — list of `%{kind, assignee, label}` describing what must happen
    - `:next_actions` — list of `%{kind, assignee, label}` of concrete next steps
    - `:progress` — scorecard and interview progress counts
  """
  def current_state(%Application{} = application) do
    application = Repo.preload(application, [:pipeline_stage])
    stage = application.pipeline_stage

    interviews =
      Treby.Interviews.InterviewEvent
      |> where([e], e.application_id == ^application.id)
      |> order_by([e], asc: e.start_at_utc)
      |> preload([:event_examiners])
      |> Repo.all()
      |> Repo.preload(event_examiners: :user)

    interview = List.first(interviews)

    {blockers, next_actions} =
      if stage && stage.stage_type == "interview" do
        interview_blockers(interview)
      else
        {[], non_interview_next_actions(stage)}
      end

    %{
      stage: stage,
      blocked?: blockers != [],
      blockers: blockers,
      next_actions: next_actions,
      progress: %{
        scorecards: scorecard_progress(interview),
        interviews: %{
          scheduled: interviews_any_status(interviews, "scheduled"),
          completed: interviews_any_status(interviews, "completed")
        }
      }
    }
  end

  defp interview_blockers(nil) do
    blocker = %{
      kind: :interview_not_scheduled,
      assignee: nil,
      label: "No interview scheduled yet"
    }

    action = %{kind: :schedule_interview, assignee: nil, label: "Schedule an interview"}
    {[blocker], [action]}
  end

  defp interview_blockers(interview) do
    pending_interview =
      if interview.status != "completed" do
        [%{kind: :interview_not_completed, assignee: nil, label: "Interview not yet completed"}]
      else
        []
      end

    pending_scorecards =
      interview.event_examiners
      |> Enum.reject(&(&1.user_id in submitted_scorecard_ids(interview.id)))
      |> Enum.map(fn ee ->
        %{
          kind: :scorecard_pending,
          assignee: %{user_id: ee.user_id, name: ee.user && ee.user.name},
          label: "#{(ee.user && ee.user.name) || "Examiner"}: scorecard missing"
        }
      end)

    blockers = pending_interview ++ pending_scorecards

    next_actions =
      cond do
        interview.status != "completed" ->
          [
            %{kind: :complete_interview, assignee: nil, label: "Mark the interview as completed"}
          ]

        blockers != [] ->
          [
            %{
              kind: :collect_scorecards,
              assignee: nil,
              label: "Collect the missing scorecards before advancing"
            }
          ]

        true ->
          [%{kind: :advance, assignee: nil, label: "Advance to the next stage"}]
      end

    {blockers, next_actions}
  end

  defp non_interview_next_actions(nil), do: []

  defp non_interview_next_actions(stage) do
    stages =
      PipelineStage
      |> where([s], s.pipeline_id == ^stage.pipeline_id)
      |> order_by([s], asc: s.position)
      |> Repo.all()

    case Enum.find_index(stages, &(&1.id == stage.id)) do
      nil ->
        []

      idx when idx < length(stages) - 1 ->
        [%{kind: :advance, assignee: nil, label: "Advance to the next stage"}]

      _ ->
        []
    end
  end

  defp scorecard_progress(nil), do: %{completed: 0, total: 0}

  defp scorecard_progress(interview) do
    total = length(interview.event_examiners)
    submitted_ids = submitted_scorecard_ids(interview.id)

    completed =
      interview.event_examiners
      |> Enum.count(&(&1.user_id in submitted_ids))

    %{completed: completed, total: total}
  end

  defp submitted_scorecard_ids(interview_id) do
    Treby.Scorecards.Scorecard
    |> where([s], s.interview_event_id == ^interview_id)
    |> select([s], s.interviewer_id)
    |> Repo.all()
  end

  defp interviews_any_status(interviews, status) do
    Enum.count(interviews, &(&1.status == status))
  end

  # Applications

  @doc """
  Lists applications for a job.

  Without `:page` in `opts` returns the full list; with `:page` returns
  `{entries, page_info}` (see `Treby.Candidates.Queries.paginate/3`).
  """
  def list_applications_for_job(job_id, opts \\ []) do
    opts = Enum.into(opts, %{})

    query =
      Application
      |> where([a], a.job_id == ^job_id)
      |> order_by([a], desc: a.inserted_at, desc: a.id)
      |> preload([:candidate, :pipeline_stage])

    case opts[:page] do
      nil -> Repo.all(query)
      page -> Queries.paginate(query, page, opts[:page_size])
    end
  end

  def list_applications_for_candidate(tenant_id, candidate_id) do
    Application
    |> where([a], a.tenant_id == ^tenant_id and a.candidate_id == ^candidate_id)
    |> preload([:job, :pipeline_stage])
    |> Repo.all()
  end

  @doc """
  Groups a job's applications by pipeline stage.

  Without `:page` in `opts` returns the full `[{stage, apps}]` list; with
  `:page` returns `{grouped, page_info}` where only the page slice is
  grouped (stages themselves are always fully listed).
  """
  def list_applications_by_stage(job_id, opts \\ []) do
    opts = Enum.into(opts, %{})
    stages = Stages.list_pipeline_stages_for_job(job_id)

    case opts[:page] do
      nil ->
        applications =
          Application
          |> where([a], a.job_id == ^job_id)
          |> preload([:candidate])
          |> Repo.all()

        group_by_stages(stages, applications)

      page ->
        {entries, page_info} =
          list_applications_for_job(job_id, page: page, page_size: opts[:page_size])

        {group_by_stages(stages, entries), page_info}
    end
  end

  defp group_by_stages(stages, applications) do
    Enum.group_by(applications, & &1.pipeline_stage_id)
    |> then(fn grouped ->
      Enum.map(stages, fn stage ->
        {stage, Map.get(grouped, stage.id, [])}
      end)
    end)
  end

  def candidate_application_counts(tenant_id, candidate_ids) do
    if candidate_ids == [] do
      %{}
    else
      Application
      |> where([a], a.tenant_id == ^tenant_id and a.candidate_id in ^candidate_ids)
      |> group_by([a], a.candidate_id)
      |> select([a], %{candidate_id: a.candidate_id, count: count(a.id)})
      |> Repo.all()
      |> Map.new(fn %{candidate_id: cid, count: n} -> {cid, n} end)
    end
  end

  def other_positions_text(counts, candidate_id) do
    total = Map.get(counts, candidate_id, 1) || 1
    other = total - 1

    if other > 0 do
      label = if other == 1, do: "position", else: "positions"
      "Also in #{other} other #{label}"
    end
  end

  def get_application!(id),
    do: Repo.get!(Application, id) |> Repo.preload([:candidate, :pipeline_stage, :job])

  def get_application(id),
    do: Repo.get(Application, id) |> Repo.preload([:candidate, :pipeline_stage, :job])

  def get_application!(tenant_id, id) do
    Application
    |> where([a], a.tenant_id == ^tenant_id and a.id == ^id)
    |> preload([:candidate, :pipeline_stage, :job])
    |> Repo.one!()
  end

  def get_application_for_candidate!(tenant_id, candidate_id, id) do
    Application
    |> where(
      [a],
      a.tenant_id == ^tenant_id and a.candidate_id == ^candidate_id and a.id == ^id
    )
    |> preload([:candidate, :pipeline_stage, :job])
    |> Repo.one!()
  end

  def get_application_for_candidate(tenant_id, candidate_id, id) do
    Application
    |> where(
      [a],
      a.tenant_id == ^tenant_id and a.candidate_id == ^candidate_id and a.id == ^id
    )
    |> preload([:candidate, :pipeline_stage, :job])
    |> Repo.one()
  end

  def create_application(attrs \\ %{}, opts \\ []) do
    result =
      attrs
      |> HelpersMap.stringify_keys()
      |> ensure_anagrafica(opts)
      |> set_duplicate_flag()
      |> then(fn attrs ->
        %Application{}
        |> Application.changeset(attrs)
        |> Repo.insert()
      end)

    case result do
      {:ok, app} ->
        Treby.Audit.log_event("application.created", "application", app.id, %{
          tenant_id: app.tenant_id,
          metadata: %{
            after: %{
              job_id: app.job_id,
              candidate_id: app.candidate_id,
              stage_id: app.pipeline_stage_id
            }
          }
        })

        {:ok, app}

      error ->
        error
    end
  end

  def build_anagrafica(%Treby.Candidates.Candidate{} = candidate) do
    %{
      "name" => candidate.name,
      "email" => candidate.email,
      "phone" => candidate.phone,
      "linkedin_url" => candidate.linkedin_url
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) || v == "" end)
    |> Map.new()
  end

  defp ensure_anagrafica(attrs, opts) do
    if Map.get(attrs, "anagrafica") || Map.get(attrs, :anagrafica) do
      attrs
    else
      case opts[:candidate] || Map.get(attrs, "candidate_id") || Map.get(attrs, :candidate_id) do
        nil ->
          attrs

        %Treby.Candidates.Candidate{} = candidate ->
          Map.put(attrs, "anagrafica", build_anagrafica(candidate))

        candidate_id ->
          case Repo.get(Treby.Candidates.Candidate, candidate_id) do
            nil -> attrs
            candidate -> Map.put(attrs, "anagrafica", build_anagrafica(candidate))
          end
      end
    end
  end

  defp set_duplicate_flag(attrs) do
    candidate_id = Map.get(attrs, "candidate_id") || Map.get(attrs, :candidate_id)
    job_id = Map.get(attrs, "job_id") || Map.get(attrs, :job_id)

    if candidate_id && job_id do
      is_duplicate? =
        Application
        |> where([a], a.candidate_id == ^candidate_id and a.job_id == ^job_id)
        |> Repo.exists?()

      attrs |> Map.put("is_duplicate", is_duplicate?)
    else
      attrs
    end
  end

  def recompute_duplicate_flags(candidate_id) do
    applications =
      Application
      |> where([a], a.candidate_id == ^candidate_id)
      |> order_by([a], asc: a.inserted_at, asc: a.id)
      |> Repo.all()

    duplicate_ids =
      applications
      |> Enum.group_by(& &1.job_id)
      |> Enum.flat_map(fn {_job_id, job_apps} -> Enum.drop(job_apps, 1) end)
      |> Enum.map(& &1.id)

    from(a in Application,
      where: a.candidate_id == ^candidate_id,
      update: [
        set: [
          is_duplicate: fragment("CASE WHEN ? THEN true ELSE false END", a.id in ^duplicate_ids)
        ]
      ]
    )
    |> Repo.update_all([])

    :ok
  end

  def move_application(%Application{} = application, stage_id, opts \\ []) do
    old_stage_id = application.pipeline_stage_id
    extra_attrs = opts[:attrs] || %{}

    result =
      application
      |> Application.changeset(Map.merge(%{pipeline_stage_id: stage_id}, extra_attrs))
      |> Repo.update()

    case result do
      {:ok, app} ->
        Phoenix.PubSub.broadcast(
          Treby.PubSub,
          "pipeline:#{app.job_id}",
          {:pipeline_updated, app.job_id}
        )

        # Log the stage change
        old_stage = if old_stage_id, do: Stages.get_pipeline_stage!(old_stage_id)
        new_stage = Stages.get_pipeline_stage!(stage_id)

        Treby.Activities.log_event(
          "application_stage_changed",
          "application",
          app.id,
          %{
            old_stage: old_stage && old_stage.name,
            new_stage: new_stage && new_stage.name,
            tenant_id: app.tenant_id
          }
        )

        # Inbox notification for stage change (if enabled)
        try do
          candidate = Repo.preload(app, :candidate).candidate

          Treby.Notifications.notify_inbox(
            app.tenant_id,
            "stage_change",
            %{
              title:
                "Stage change: #{(candidate && candidate.name) || "Candidate"} → #{new_stage && new_stage.name}",
              body:
                "#{(candidate && candidate.name) || "Candidate"} moved from #{(old_stage && old_stage.name) || "—"} to #{(new_stage && new_stage.name) || "—"}",
              link: "/app/candidates/#{candidate && candidate.id}"
            },
            opts[:actor] && opts[:actor].id
          )
        rescue
          _ -> :ok
        catch
          _, _ -> :ok
        end

        log_stage_moved(app, old_stage, new_stage, old_stage_id, stage_id, opts)

        # Send stage change notification email if not skipped (non-blocking:
        # failures are logged + metered, never fail the move; :skip throws
        # are deliberate preference skips and stay silent)
        unless opts[:skip_notification] do
          notify_fn = opts[:notify_fn] || (&Treby.Notifications.notify_stage_change/2)

          try do
            notify_fn.(app, opts[:actor])
          rescue
            e ->
              error = Exception.message(e)

              Logger.warning("[pipeline] notify_stage_change failed",
                application_id: app.id,
                error: error
              )

              :telemetry.execute(
                [:treby, :pipeline, :notify_failed],
                %{count: 1},
                %{application_id: app.id, error: error}
              )

              :ok
          catch
            :throw, :skip ->
              :ok

            kind, reason ->
              error = "#{inspect(kind)}: #{inspect(reason)}"

              Logger.warning("[pipeline] notify_stage_change failed",
                application_id: app.id,
                error: error
              )

              :telemetry.execute(
                [:treby, :pipeline, :notify_failed],
                %{count: 1},
                %{application_id: app.id, error: error}
              )

              :ok
          end
        end

        {:ok, app}

      error ->
        error
    end
  end

  defp log_stage_moved(app, old_stage, new_stage, old_stage_id, stage_id, opts) do
    audit_extra = opts[:audit] || %{}

    Treby.Audit.log_event(
      "application.stage_moved",
      "application",
      app.id,
      Map.merge(
        %{
          tenant_id: app.tenant_id,
          actor_id: opts[:actor] && opts[:actor].id,
          metadata: %{
            before: %{stage_id: old_stage_id, stage_name: old_stage && old_stage.name},
            after: %{stage_id: stage_id, stage_name: new_stage && new_stage.name}
          }
        },
        audit_extra
      )
    )
  end

  def subscribe_to_pipeline(job_id) do
    Phoenix.PubSub.subscribe(Treby.PubSub, "pipeline:#{job_id}")
  end

  # Review state

  def mark_reviewed(%Application{} = application) do
    application
    |> Application.changeset(%{reviewed: true})
    |> Repo.update()
  end

  def mark_unreviewed(%Application{} = application) do
    application
    |> Application.changeset(%{reviewed: false})
    |> Repo.update()
  end

  def toggle_reviewed(%Application{} = application) do
    application
    |> Application.changeset(%{reviewed: not application.reviewed})
    |> Repo.update()
  end
end
