defmodule Treby.Candidates.Duplicates do
  @moduledoc """
  Duplicate candidate detection: normalization helpers and merge-group suggestions.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Candidates.Candidate

  def normalize_email(nil), do: ""

  def normalize_email(email) when is_binary(email),
    do: email |> String.trim() |> String.downcase()

  def normalize_phone(nil), do: ""
  def normalize_phone(""), do: ""

  def normalize_phone(phone) when is_binary(phone) do
    digits = phone |> String.trim() |> String.replace(~r/[^\d]/, "")

    digits =
      case digits do
        "0039" <> rest -> rest
        "39" <> rest when byte_size(digits) > 8 -> rest
        _ -> digits
      end

    digits
  end

  def normalize_name(nil), do: ""
  def normalize_name(""), do: ""

  def normalize_name(name) when is_binary(name) do
    name
    |> String.normalize(:nfd)
    |> strip_combining_marks()
    |> String.downcase()
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp strip_combining_marks(string) do
    string
    |> String.to_charlist()
    |> Enum.reject(&combining_mark?/1)
    |> List.to_string()
  end

  defp combining_mark?(codepoint) do
    (codepoint >= 0x0300 and codepoint <= 0x036F) or
      (codepoint >= 0x1AB0 and codepoint <= 0x1AFF) or
      (codepoint >= 0x1DC0 and codepoint <= 0x1DFF) or
      (codepoint >= 0x20D0 and codepoint <= 0x20FF) or
      (codepoint >= 0xFE20 and codepoint <= 0xFE2F)
  end

  def email_local_part(nil), do: ""
  def email_local_part(""), do: ""

  def email_local_part(email) when is_binary(email) do
    email |> normalize_email() |> String.split("@") |> List.first() || ""
  end

  @doc """
  Returns duplicate groups for a tenant as a list of maps:

      %{
        id: binary,
        signal: :exact_email | :phone_name | :name_local_part,
        confidence: :high | :medium,
        auto_merge: boolean,
        candidates: [%Candidate{}],
        default_primary_id: id
      }

  Each candidate belongs to at most one group. Signals are processed
  strongest-first: exact email, then normalized phone + name, then
  normalized name + email local part. Exact-email groups are flagged for
  auto-merge, all others are suggestions.
  """
  def list_duplicate_groups(tenant_id) do
    candidates =
      Candidate
      |> where([c], c.tenant_id == ^tenant_id and is_nil(c.merged_into_id))
      # `id` is a deterministic tiebreaker so two candidates with the same
      # `inserted_at` (possible when inserts happen within the same microsecond)
      # produce a stable, reproducible ordering for auto-merge.
      |> order_by([c], asc: c.inserted_at, asc: c.id)
      |> Repo.all()

    cid_map = Map.new(candidates, &{&1.id, &1})

    classes = [
      {build_email_groups(candidates), :exact_email, :high, true},
      {build_phone_name_groups(candidates), :phone_name, :high, false},
      {build_name_local_part_groups(candidates), :name_local_part, :medium, false}
    ]

    {groups, _used} =
      Enum.reduce(classes, {[], MapSet.new()}, fn {id_groups, signal, confidence, auto_merge},
                                                  {groups, used} ->
        id_groups =
          Enum.reject(id_groups, fn ids ->
            Enum.any?(ids, &MapSet.member?(used, &1))
          end)

        new_groups =
          Enum.map(id_groups, fn ids ->
            members = Enum.map(ids, &Map.fetch!(cid_map, &1))
            sorted_ids = Enum.map(ids, &to_string/1) |> Enum.sort()

            %{
              id:
                :crypto.hash(:sha256, :erlang.term_to_binary(sorted_ids))
                |> Base.encode16(case: :lower),
              signal: signal,
              confidence: confidence,
              auto_merge: auto_merge,
              candidates: members,
              default_primary_id: List.first(members).id
            }
          end)

        new_used =
          Enum.reduce(id_groups, used, fn ids, acc ->
            Enum.reduce(ids, acc, &MapSet.put(&2, &1))
          end)

        {groups ++ new_groups, new_used}
      end)

    groups
  end

  @doc """
  Whether the tenant has more than one active candidate with the given email
  (used to flag re-applications from a previously merged-away email).
  """
  def has_exact_email_duplicate?(tenant_id, email) do
    normalized = normalize_email(email)

    if normalized == "" do
      false
    else
      Candidate
      |> where(
        [c],
        c.tenant_id == ^tenant_id and is_nil(c.merged_into_id) and
          fragment("lower(trim(?)) = ?", c.email, ^normalized)
      )
      |> Repo.all()
      |> length()
      |> Kernel.>(1)
    end
  end

  defp build_email_groups(candidates) do
    candidates
    |> Enum.reject(fn c -> normalize_email(c.email) == "" end)
    |> Enum.group_by(fn c -> normalize_email(c.email) end)
    |> Enum.filter(fn {_email, members} -> length(members) > 1 end)
    |> Enum.map(fn {_email, members} -> Enum.map(members, & &1.id) end)
  end

  defp build_phone_name_groups(candidates) do
    candidates
    |> Enum.filter(fn c ->
      normalize_phone(c.phone) != "" and normalize_name(c.name) != ""
    end)
    |> Enum.group_by(fn c -> {normalize_phone(c.phone), normalize_name(c.name)} end)
    |> Enum.filter(fn {_key, members} -> length(members) > 1 end)
    |> Enum.map(fn {_key, members} -> Enum.map(members, & &1.id) end)
  end

  defp build_name_local_part_groups(candidates) do
    candidates
    |> Enum.filter(fn c ->
      normalize_name(c.name) != "" and email_local_part(c.email) != ""
    end)
    |> Enum.group_by(fn c -> {normalize_name(c.name), email_local_part(c.email)} end)
    |> Enum.filter(fn {_key, members} -> length(members) > 1 end)
    |> Enum.map(fn {_key, members} -> Enum.map(members, & &1.id) end)
  end
end
