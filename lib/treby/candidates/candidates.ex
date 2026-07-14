defmodule Treby.Candidates do
  @moduledoc """
  The Candidates context.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Candidates.Candidate

  def list_candidates(tenant_id) do
    Candidate
    |> where([c], c.tenant_id == ^tenant_id)
    |> order_by([c], c.name)
    |> Repo.all()
  end

  def get_candidate!(id), do: Repo.get!(Candidate, id)

  def get_candidate!(tenant_id, id) do
    Candidate
    |> where([c], c.tenant_id == ^tenant_id and c.id == ^id)
    |> Repo.one!()
  end

  def find_or_create_candidate(tenant_id, attrs) do
    email = String.downcase(attrs["email"] || attrs[:email])

    case Repo.get_by(Candidate, tenant_id: tenant_id, email: email) do
      nil -> create_candidate(Map.put(attrs, "tenant_id", tenant_id))
      candidate -> {:ok, candidate}
    end
  end

  def create_candidate(attrs \\ %{}) do
    %Candidate{}
    |> Candidate.changeset(attrs)
    |> Repo.insert()
  end

  def update_candidate(%Candidate{} = candidate, attrs) do
    candidate
    |> Candidate.changeset(attrs)
    |> Repo.update()
  end

  def delete_candidate(%Candidate{} = candidate) do
    Repo.delete(candidate)
  end

  def change_candidate(%Candidate{} = candidate, attrs \\ %{}) do
    Candidate.changeset(candidate, attrs)
  end
end
