defmodule Treby.Candidates do
  @moduledoc """
  The Candidates context.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Candidates.Candidate
  alias Treby.Candidates.MergeLog
  alias Treby.Candidates.Duplicates
  alias Treby.Candidates.DismissedMergeGroup
  alias Treby.CandidatePortal.Conversation
  alias Treby.Activities.ActivityLog
  alias Treby.Pipeline.Application

  @auto_merge_max_candidates 5_000

  def list_candidates(tenant_id, filters \\ %{}) do
    Candidate
    |> where([c], c.tenant_id == ^tenant_id and is_nil(c.merged_into_id))
    |> apply_search(filters[:search])
    |> apply_job_filter(filters[:job_id])
    |> apply_stage_filter(filters[:stage_id])
    |> order_by([c], c.name)
    |> Repo.all()
  end

  defp apply_search(query, nil), do: query
  defp apply_search(query, ""), do: query

  defp apply_search(query, search) do
    pattern = "%#{search}%"

    query
    |> where([c], ilike(c.name, ^pattern) or ilike(c.email, ^pattern))
  end

  defp apply_job_filter(query, nil), do: query
  defp apply_job_filter(query, ""), do: query

  defp apply_job_filter(query, job_id) do
    import Ecto.Query

    subquery =
      Treby.Pipeline.Application
      |> where([a], a.job_id == ^job_id)
      |> select([a], a.candidate_id)

    where(query, [c], c.id in subquery(subquery))
  end

  defp apply_stage_filter(query, nil), do: query
  defp apply_stage_filter(query, ""), do: query

  defp apply_stage_filter(query, stage_id) do
    import Ecto.Query

    subquery =
      Treby.Pipeline.Application
      |> where([a], a.pipeline_stage_id == ^stage_id)
      |> select([a], a.candidate_id)

    where(query, [c], c.id in subquery(subquery))
  end

  def get_candidate!(id), do: Repo.get!(Candidate, id)

  def get_candidate!(tenant_id, id) do
    Candidate
    |> where([c], c.tenant_id == ^tenant_id and c.id == ^id and is_nil(c.merged_into_id))
    |> Repo.one!()
  end

  @doc """
  Returns a candidate regardless of merge state (including absorbed/tombstoned
  candidates), or `nil`. Used to detect and redirect away from absorbed profiles.
  """
  def get_candidate(tenant_id, id) do
    Candidate
    |> where([c], c.tenant_id == ^tenant_id and c.id == ^id)
    |> Repo.one()
  end

  @doc """
  Create a candidate or find the existing active candidate with the same
  normalized email. When no email is present the candidate is always created.
  Absorbed (tombstoned) candidates are never matched. This is the single entry
  point for candidate creation that must not produce duplicates (career page
  applications, CSV import, manual add).
  """
  def create_or_find(tenant_id, attrs) do
    attrs = Map.new(attrs, fn {k, v} -> {to_string(k), v} end)
    email = attrs["email"] || ""
    email = email |> String.trim() |> String.downcase()

    candidate =
      if email == "" do
        nil
      else
        Candidate
        |> where(
          [c],
          c.tenant_id == ^tenant_id and is_nil(c.merged_into_id) and
            fragment("lower(trim(?)) = ?", c.email, ^email)
        )
        |> Repo.one()
      end

    case candidate do
      nil -> create_candidate(Map.put(attrs, "tenant_id", tenant_id))
      candidate -> {:ok, candidate}
    end
  end

  def create_candidate(attrs \\ %{}) do
    tenant_id = attrs["tenant_id"] || attrs[:tenant_id]

    result =
      %Candidate{tenant_id: tenant_id}
      |> Candidate.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, candidate} ->
        Treby.Activities.log_event(
          "candidate_created",
          "candidate",
          candidate.id,
          %{tenant_id: candidate.tenant_id}
        )

        {:ok, candidate}

      error ->
        error
    end
  end

  def update_candidate(%Candidate{} = candidate, attrs, metadata \\ %{}) do
    result =
      candidate
      |> Candidate.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, updated} ->
        Treby.Activities.log_event(
          "candidate_updated",
          "candidate",
          updated.id,
          Map.merge(metadata, %{tenant_id: updated.tenant_id})
        )

        {:ok, updated}

      error ->
        error
    end
  end

  def delete_candidate(%Candidate{} = candidate, actor \\ nil) do
    if actor && actor.role != "admin" do
      {:error, :unauthorized}
    else
      Repo.delete(candidate)
    end
  end

  def change_candidate(%Candidate{} = candidate, attrs \\ %{}) do
    Candidate.changeset(candidate, attrs)
  end

  def tenant_has_candidates?(tenant_id) do
    Candidate
    |> where([c], c.tenant_id == ^tenant_id)
    |> Repo.exists?()
  end

  # Merge & split

  @doc """
  Merge a list of `absorbed_list` candidates into `primary`. All applications,
  email threads, and candidate-level activity log rows are reassigned to the
  primary; absorbed candidates are tombstoned; merge log rows are created to
  allow undo. Returns `{:ok, %{primary: %Candidate{}, merge_logs: [MergeLog]}}`.

  Guardrails:
    * `primary` must not be tombstoned
    * every absorbed candidate must not be tombstoned and must belong to the
      same tenant as the primary
    * a candidate cannot be merged with itself
  """
  def merge_candidates(%Candidate{} = primary, absorbed_list, actor \\ nil) do
    absorbed_list = List.wrap(absorbed_list)

    case validate_merge_targets(primary, absorbed_list) do
      :ok ->
        Repo.transaction(fn ->
          merge_logs =
            Enum.map(absorbed_list, fn absorbed ->
              do_merge(primary, absorbed, actor)
            end)

          Treby.Pipeline.recompute_duplicate_flags(primary.id)

          %{primary: primary, merge_logs: merge_logs}
        end)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_merge_targets(%Candidate{} = primary, absorbed_list) do
    cond do
      absorbed_list == [] ->
        {:error, :no_candidates_to_merge}

      primary.merged_into_id != nil ->
        {:error, :primary_is_tombstoned}

      Enum.any?(absorbed_list, fn a -> a.id == primary.id end) ->
        {:error, :cannot_merge_with_itself}

      Enum.any?(absorbed_list, fn a -> a.merged_into_id != nil end) ->
        {:error, :cannot_merge_tombstoned_candidate}

      Enum.any?(absorbed_list, fn a -> a.tenant_id != primary.tenant_id end) ->
        {:error, :cross_tenant_merge}

      true ->
        :ok
    end
  end

  defp do_merge(%Candidate{} = primary, %Candidate{} = absorbed, actor) do
    now = DateTime.utc_now()

    application_mapping = reassign_to_primary(Application, :candidate_id, absorbed.id, primary.id)

    conversation_mapping =
      reassign_to_primary(Conversation, :candidate_id, absorbed.id, primary.id)

    activity_mapping = reassign_candidate_activities(absorbed.id, primary.id)

    from(c in Candidate, where: c.id == ^absorbed.id)
    |> Repo.update_all(set: [merged_into_id: primary.id, merged_at: now])

    {:ok, merge_log} =
      %MergeLog{}
      |> MergeLog.changeset(%{
        primary_candidate_id: primary.id,
        absorbed_candidate_id: absorbed.id,
        tenant_id: primary.tenant_id,
        actor_id: actor && actor.id,
        merged_at: now,
        application_mapping: stringify_keys(application_mapping),
        thread_mapping: stringify_keys(conversation_mapping),
        activity_mapping: stringify_keys(activity_mapping)
      })
      |> Repo.insert()

    Treby.Activities.log_event(
      "candidates_merged",
      "candidate",
      primary.id,
      %{
        actor_id: actor && actor.id,
        tenant_id: primary.tenant_id,
        absorbed_candidate_id: absorbed.id
      }
    )

    merge_log
  end

  defp reassign_to_primary(schema, field_name, from_id, to_id) do
    ids =
      schema
      |> where([e], field(e, ^field_name) == ^from_id)
      |> select([e], e.id)
      |> Repo.all()

    from(e in schema, where: field(e, ^field_name) == ^from_id)
    |> Repo.update_all(set: [{field_name, to_id}])

    Map.new(ids, &{&1, from_id})
  end

  defp reassign_candidate_activities(from_id, to_id) do
    ids =
      ActivityLog
      |> where([a], a.entity_type == "candidate" and a.entity_id == ^from_id)
      |> select([a], a.id)
      |> Repo.all()

    from(a in ActivityLog,
      where: a.entity_type == "candidate" and a.entity_id == ^from_id
    )
    |> Repo.update_all(set: [entity_id: to_id])

    Map.new(ids, &{&1, from_id})
  end

  @doc """
  Undo a previously executed merge, restoring entity assignments to the
  absorbed candidate and reactivating it. Only the outermost merge in a chain
  can be undone — if the primary has itself been absorbed after this merge,
  the undo is refused.
  """
  def undo_merge(%MergeLog{} = merge_log, actor \\ nil) do
    primary = Repo.get(Candidate, merge_log.primary_candidate_id)
    absorbed = Repo.get(Candidate, merge_log.absorbed_candidate_id)

    cond do
      is_nil(primary) or primary.merged_into_id != nil ->
        {:error, :primary_no_longer_mergeable}

      is_nil(absorbed) or absorbed.merged_into_id != primary.id ->
        {:error, :absorbed_not_in_expected_state}

      true ->
        Repo.transaction(fn ->
          restore_owner(Application, :candidate_id, merge_log.application_mapping, absorbed.id)
          restore_owner(Conversation, :candidate_id, merge_log.thread_mapping, absorbed.id)
          restore_owner(ActivityLog, :entity_id, merge_log.activity_mapping, absorbed.id)

          from(c in Candidate, where: c.id == ^absorbed.id)
          |> Repo.update_all(set: [merged_into_id: nil, merged_at: nil])

          Repo.delete!(merge_log)

          Treby.Activities.log_event(
            "candidates_merge_undone",
            "candidate",
            primary.id,
            %{
              actor_id: actor && actor.id,
              tenant_id: primary.tenant_id,
              absorbed_candidate_id: absorbed.id
            }
          )

          Treby.Pipeline.recompute_duplicate_flags(primary.id)

          %{primary: primary, absorbed: absorbed}
        end)
    end
  end

  defp restore_owner(schema, field_name, mapping, target_id) do
    ids = parse_mapping_ids(mapping)

    if ids != [] do
      from(e in schema, where: e.id in ^ids)
      |> Repo.update_all(set: [{field_name, target_id}])
    end

    :ok
  end

  defp parse_mapping_ids(mapping) do
    mapping
    |> Map.keys()
    |> Enum.map(&Ecto.UUID.cast(to_string(&1)))
    |> Enum.flat_map(fn
      {:ok, id} -> [id]
      :error -> []
    end)
  end

  defp stringify_keys(mapping) do
    Map.new(mapping, fn {k, v} -> {to_string(k), to_string(v)} end)
  end

  @doc """
  List suggested duplicate groups for a tenant. See
  `Treby.Candidates.Duplicates.list_duplicate_groups/1`.
  """
  defdelegate list_duplicate_groups(tenant_id), to: Duplicates

  @doc """
  List the group keys (`group.id` values) of duplicate suggestions a tenant has
  dismissed, as a `MapSet`. Dismissed groups stay hidden across page loads.
  """
  def list_dismissed_group_keys(tenant_id) do
    DismissedMergeGroup
    |> where([d], d.tenant_id == ^tenant_id)
    |> select([d], d.group_key)
    |> Repo.all()
    |> MapSet.new()
  end

  @doc """
  List duplicate suggestion groups for a tenant with dismissed groups removed.
  See `Treby.Candidates.Duplicates.list_duplicate_groups/1`.
  """
  def list_suggestion_groups(tenant_id) do
    dismissed = list_dismissed_group_keys(tenant_id)

    tenant_id
    |> list_duplicate_groups()
    |> Enum.reject(&MapSet.member?(dismissed, &1.id))
  end

  @doc """
  Persist a dismissal for a duplicate suggestion group. Idempotent — dismissing
  a group that was already dismissed is a no-op returning `{:ok, existing}`.
  Returns `{:error, changeset}` on validation failure.
  """
  def dismiss_merge_group(tenant_id, group_key, actor \\ nil) do
    %DismissedMergeGroup{}
    |> DismissedMergeGroup.changeset(%{
      tenant_id: tenant_id,
      group_key: group_key,
      dismissed_by: actor && actor.id,
      dismissed_at: DateTime.utc_now()
    })
    |> Repo.insert(
      on_conflict: :nothing,
      conflict_target: [:tenant_id, :group_key]
    )
  end

  @doc """
  Automatically merge duplicate groups that share an exact normalized email
  (the only signal considered safe to merge without review). The oldest
  candidate in each group is used as the primary. Runs on demand, guarded by a
  tenant candidate-count cap so it stays cheap on large workspaces. Returns
  `%{merged: n, skipped: n}`.
  """
  def auto_merge_exact_email(tenant_id, actor \\ nil) do
    if candidate_count(tenant_id) > @auto_merge_max_candidates do
      %{merged: 0, skipped: 0}
    else
      groups =
        tenant_id
        |> list_duplicate_groups()
        |> Enum.filter(& &1.auto_merge)

      Enum.reduce(groups, %{merged: 0, skipped: 0}, fn group, acc ->
        primary = Enum.find(group.candidates, &(&1.id == group.default_primary_id))
        absorbed = Enum.reject(group.candidates, &(&1.id == group.default_primary_id))

        case merge_candidates(primary, absorbed, actor) do
          {:ok, _} -> %{acc | merged: acc.merged + 1}
          {:error, _} -> %{acc | skipped: acc.skipped + 1}
        end
      end)
    end
  end

  defp candidate_count(tenant_id) do
    Candidate
    |> where([c], c.tenant_id == ^tenant_id and is_nil(c.merged_into_id))
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Fetch a merge log row by id, raising if not found.
  """
  def get_merge_log!(id) do
    Repo.get!(MergeLog, id)
  end

  @doc """
  List merge log rows where the given candidate is the surviving primary,
  oldest first.
  """
  def list_merge_logs_for_primary(primary_id) do
    MergeLog
    |> where([m], m.primary_candidate_id == ^primary_id)
    |> order_by([m], asc: m.inserted_at)
    |> preload([:absorbed_candidate])
    |> Repo.all()
  end

  @doc """
  Whether the given merge log row can still be undone (the primary is active
  and the absorbed candidate is still tombstoned into it).
  """
  def merge_undoable?(%MergeLog{} = merge_log) do
    primary = Repo.get(Candidate, merge_log.primary_candidate_id)
    absorbed = Repo.get(Candidate, merge_log.absorbed_candidate_id)

    not is_nil(primary) and is_nil(primary.merged_into_id) and not is_nil(absorbed) and
      absorbed.merged_into_id == primary.id
  end
end
