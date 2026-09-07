defmodule Treby.Candidates do
  @moduledoc """
  The Candidates context facade.

  Delegates listing/search/filter to `Treby.Candidates.Queries` and
  merge/undo to `Treby.Candidates.Merge`. Core CRUD stays here.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Candidates.Candidate
  alias Treby.Candidates.Merge
  alias Treby.Candidates.Queries

  # Listing (delegated to Queries)

  defdelegate list_candidates(tenant_id, filters \\ %{}), to: Queries

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

  Race-safe: the partial unique index `candidates_tenant_email_unique_active`
  arbitrates concurrent inserts; a loser re-reads and returns the winner.
  """
  def create_or_find(tenant_id, attrs) do
    attrs = Map.new(attrs, fn {k, v} -> {to_string(k), v} end)
    email = attrs["email"] || ""
    email = email |> String.trim() |> String.downcase()

    case find_active_candidate(tenant_id, email) do
      %Candidate{} = candidate ->
        {:ok, candidate}

      nil when email == "" ->
        create_candidate(Map.put(attrs, "tenant_id", tenant_id))

      nil ->
        case create_candidate(Map.put(attrs, "tenant_id", tenant_id)) do
          {:error, %Ecto.Changeset{} = changeset} = error ->
            if unique_email_violation?(changeset) do
              case find_active_candidate(tenant_id, email) do
                %Candidate{} = winner -> {:ok, winner}
                nil -> error
              end
            else
              error
            end

          result ->
            result
        end
    end
  end

  defp find_active_candidate(_tenant_id, ""), do: nil

  defp find_active_candidate(tenant_id, email) do
    Candidate
    |> where(
      [c],
      c.tenant_id == ^tenant_id and is_nil(c.merged_into_id) and
        fragment("lower(trim(?)) = ?", c.email, ^email)
    )
    |> Repo.one()
  end

  defp unique_email_violation?(%Ecto.Changeset{} = changeset) do
    Enum.any?(changeset.errors, fn
      {:email, {_message, opts}} ->
        to_string(Keyword.get(opts, :constraint_name, "")) ==
          "candidates_tenant_email_unique_active"

      _ ->
        false
    end)
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

        Treby.Audit.log_event("candidate.created", "candidate", candidate.id, %{
          tenant_id: candidate.tenant_id,
          actor_id: attrs["actor_id"] || attrs[:actor_id],
          metadata: %{after: %{name: candidate.name, email: candidate.email}}
        })

        {:ok, candidate}

      error ->
        error
    end
  end

  def update_candidate(%Candidate{} = candidate, attrs, metadata \\ %{}) do
    before = Map.take(candidate, [:name, :email, :phone])

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

        Treby.Audit.log_event("candidate.updated", "candidate", updated.id, %{
          tenant_id: updated.tenant_id,
          actor_id: metadata[:actor_id] || metadata["actor_id"],
          metadata: %{
            before: before,
            after: Map.take(updated, [:name, :email, :phone])
          }
        })

        {:ok, updated}

      error ->
        error
    end
  end

  def delete_candidate(%Candidate{} = candidate, actor \\ nil) do
    if actor && actor.role != "admin" do
      {:error, :unauthorized}
    else
      case Repo.delete(candidate) do
        {:ok, deleted} ->
          Treby.Audit.log_event("candidate.deleted", "candidate", deleted.id, %{
            tenant_id: deleted.tenant_id,
            actor_id: actor && actor.id,
            metadata: %{before: %{name: deleted.name, email: deleted.email}}
          })

          {:ok, deleted}

        error ->
          error
      end
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

  # Merge & duplicates (delegated to Merge)

  defdelegate merge_candidates(primary, absorbed_list, actor \\ nil), to: Merge
  defdelegate undo_merge(merge_log, actor \\ nil), to: Merge
  defdelegate get_merge_log!(id), to: Merge
  defdelegate list_merge_logs_for_primary(primary_id), to: Merge
  defdelegate merge_undoable?(merge_log), to: Merge
  defdelegate list_duplicate_groups(tenant_id), to: Merge
  defdelegate list_dismissed_group_keys(tenant_id), to: Merge
  defdelegate list_suggestion_groups(tenant_id), to: Merge
  defdelegate dismiss_merge_group(tenant_id, group_key, actor \\ nil), to: Merge
  defdelegate auto_merge_exact_email(tenant_id, actor \\ nil), to: Merge
end
