defmodule Treby.Invites do
  @moduledoc """
  The Invites context.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Invites.Invite

  def list_invites(tenant_id) do
    Invite
    |> where([i], i.tenant_id == ^tenant_id and is_nil(i.accepted_at))
    |> order_by([i], desc: i.inserted_at)
    |> Repo.all()
  end

  def get_invite_by_token(token) do
    Invite
    |> where([i], i.token == ^token and is_nil(i.accepted_at))
    |> where([i], i.expires_at > ^DateTime.utc_now())
    |> Repo.one()
  end

  def create_invite(attrs \\ %{}) do
    token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

    expires_at = DateTime.utc_now() |> DateTime.add(7, :day)

    %Invite{}
    |> Invite.changeset(Map.merge(attrs, %{"token" => token, "expires_at" => expires_at}))
    |> Repo.insert()
  end

  def accept_invite(%Invite{} = invite) do
    invite
    |> Invite.changeset(%{accepted_at: DateTime.utc_now()})
    |> Repo.update()
  end

  def delete_invite(%Invite{} = invite) do
    Repo.delete(invite)
  end
end
