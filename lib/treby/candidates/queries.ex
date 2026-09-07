defmodule Treby.Candidates.Queries do
  @moduledoc """
  Candidate listing and filtering helpers.

  Extracted from `Treby.Candidates`. Single top-level `import Ecto.Query`
  with no inline imports.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Candidates.Candidate

  @max_page_size 100

  @doc """
  Lists active candidates for a tenant.

  Without `:page` in `filters` returns the full list (used by lookups such
  as OTP and merge). With `:page` returns `{entries, page_info}` where
  `page_info` is `%{page:, page_size:, total_count:, total_pages:}`.
  """
  def list_candidates(tenant_id, filters \\ %{}) do
    query =
      Candidate
      |> where([c], c.tenant_id == ^tenant_id and is_nil(c.merged_into_id))
      |> apply_search(filters[:search])
      |> apply_job_filter(filters[:job_id])
      |> apply_stage_filter(filters[:stage_id])
      |> order_by([c], asc: c.name, asc: c.id)

    case filters[:page] do
      nil -> Repo.all(query)
      page -> paginate(query, page, filters[:page_size])
    end
  end

  @doc """
  Paginates any query, returning `{entries, page_info}`.

  `page` accepts integers or URL-param strings (invalid → 1).
  `page_size` defaults to `config :treby, :default_page_size` (max 100).
  """
  @spec paginate(Ecto.Queryable.t(), term(), term()) :: {list(), map()}
  def paginate(queryable, page, page_size \\ nil) do
    %Ecto.Query{} = query = Ecto.Queryable.to_query(queryable)
    size = normalize_page_size(page_size)

    total =
      query
      |> exclude(:order_by)
      |> exclude(:preload)
      |> exclude(:limit)
      |> exclude(:offset)
      |> Repo.aggregate(:count)

    total_pages = max(1, ceil_div(total, size))
    page_number = page |> normalize_page() |> min(total_pages)
    offset = (page_number - 1) * size

    entries =
      query
      |> limit(^size)
      |> offset(^offset)
      |> Repo.all()

    {entries, %{page: page_number, page_size: size, total_count: total, total_pages: total_pages}}
  end

  @doc """
  Default page size from config.
  """
  @spec default_page_size() :: pos_integer()
  def default_page_size do
    Application.get_env(:treby, :default_page_size, 25)
  end

  defp normalize_page(page) when is_integer(page) and page >= 1, do: page

  defp normalize_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {n, _} when n >= 1 -> n
      _ -> 1
    end
  end

  defp normalize_page(_), do: 1

  defp normalize_page_size(nil), do: default_page_size()
  defp normalize_page_size(size) when is_integer(size), do: size |> max(1) |> min(@max_page_size)

  defp normalize_page_size(size) when is_binary(size) do
    case Integer.parse(size) do
      {n, _} -> normalize_page_size(n)
      :error -> default_page_size()
    end
  end

  defp normalize_page_size(_), do: default_page_size()

  defp ceil_div(total, size), do: div(total + size - 1, size)

  def base_active_query(tenant_id) do
    Candidate
    |> where([c], c.tenant_id == ^tenant_id and is_nil(c.merged_into_id))
  end

  def apply_search(query, nil), do: query
  def apply_search(query, ""), do: query

  def apply_search(query, search) do
    pattern = "%#{escape_like(search)}%"

    query
    |> where([c], ilike(c.name, ^pattern) or ilike(c.email, ^pattern))
  end

  @doc """
  Escapes `%`, `_` and `\\` so user input matches literally in `ilike`
  patterns. PostgreSQL treats backslash as the default `LIKE` escape
  character, so no `ESCAPE` clause is needed.
  """
  @spec escape_like(String.t()) :: String.t()
  def escape_like(search) when is_binary(search) do
    search
    |> String.replace("\\", "\\\\")
    |> String.replace("%", "\\%")
    |> String.replace("_", "\\_")
  end

  def apply_job_filter(query, nil), do: query
  def apply_job_filter(query, ""), do: query

  def apply_job_filter(query, job_id) do
    subquery =
      Treby.Pipeline.Application
      |> where([a], a.job_id == ^job_id)
      |> select([a], a.candidate_id)

    where(query, [c], c.id in subquery(subquery))
  end

  def apply_stage_filter(query, nil), do: query
  def apply_stage_filter(query, ""), do: query

  def apply_stage_filter(query, stage_id) do
    subquery =
      Treby.Pipeline.Application
      |> where([a], a.pipeline_stage_id == ^stage_id)
      |> select([a], a.candidate_id)

    where(query, [c], c.id in subquery(subquery))
  end
end
