defmodule Treby.Notes do
  @moduledoc """
  The Notes context.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Notes.Note

  def list_notes_for_application(application_id) do
    Note
    |> where([n], n.application_id == ^application_id)
    |> preload([:author])
    |> order_by([n], desc: n.inserted_at)
    |> Repo.all()
  end

  def get_note!(id), do: Repo.get!(Note, id) |> preload([:author])

  def get_note!(tenant_id, id) do
    Note
    |> where([n], n.tenant_id == ^tenant_id and n.id == ^id)
    |> preload([:author])
    |> Repo.one!()
  end

  def create_note(attrs \\ %{}) do
    %Note{}
    |> Note.changeset(attrs)
    |> Repo.insert()
  end

  def update_note(%Note{} = note, attrs) do
    note
    |> Note.changeset(attrs)
    |> Repo.update()
  end

  def delete_note(%Note{} = note) do
    Repo.delete(note)
  end

  def change_note(%Note{} = note, attrs \\ %{}) do
    Note.changeset(note, attrs)
  end
end
