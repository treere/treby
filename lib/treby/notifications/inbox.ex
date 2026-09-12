defmodule Treby.Notifications.Inbox do
  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Notifications.Notification

  @doc """
  Fan-out: create one notification per tenant member.
  Respects inbox preference if type is known; caller should check pref before calling,
  but this also guards.
  Returns {:ok, [notifications]}.
  """
  def create_for_tenant(tenant_id, attrs, actor_id \\ nil) do
    tenant = Treby.Tenants.get_tenant!(tenant_id)

    type = attrs[:type] || attrs["type"]

    # Respect inbox pref if type has a toggle
    if type && !Treby.Notifications.inbox_enabled?(tenant, type) do
      {:ok, []}
    else
      members = Treby.Memberships.list_users_for_tenant(tenant_id)

      if members == [] do
        {:ok, []}
      else
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        rows =
          Enum.map(members, fn user ->
            %{
              id: Ecto.UUID.generate(),
              tenant_id: tenant_id,
              recipient_id: user.id,
              actor_id: actor_id,
              type: to_string(type),
              title: attrs[:title] || attrs["title"] || type,
              body: attrs[:body] || attrs["body"],
              link: attrs[:link] || attrs["link"],
              read_at: nil,
              inserted_at: now,
              updated_at: now
            }
          end)

        {count, _} = Repo.insert_all(Notification, rows)

        # fetch back inserted rows for PubSub
        inserted =
          Repo.all(
            from n in Notification,
              where: n.tenant_id == ^tenant_id and n.inserted_at == ^now,
              order_by: [desc: n.inserted_at]
          )
          |> Enum.filter(fn n -> n.type == to_string(type) end)
          |> Enum.take(count)

        Enum.each(inserted, fn n ->
          Phoenix.PubSub.broadcast(
            Treby.PubSub,
            "notifications:#{n.recipient_id}",
            {:new_notification, n}
          )
        end)

        {:ok, inserted}
      end
    end
  end

  def list_for_user(user_id, tenant_id, opts \\ []) do
    filter = Keyword.get(opts, :filter, :all)
    type = Keyword.get(opts, :type)
    search = Keyword.get(opts, :search)
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    base =
      from n in Notification,
        where: n.recipient_id == ^user_id and n.tenant_id == ^tenant_id,
        order_by: [desc: n.inserted_at]

    base =
      case filter do
        :unread -> where(base, [n], is_nil(n.read_at))
        _ -> base
      end

    base =
      if type && type != "" do
        where(base, [n], n.type == ^type)
      else
        base
      end

    base =
      if search && search != "" do
        pattern = "%#{search}%"
        where(base, [n], ilike(n.title, ^pattern) or ilike(n.body, ^pattern))
      else
        base
      end

    base |> limit(^limit) |> offset(^offset) |> Repo.all()
  end

  def counts(user_id, tenant_id) do
    total =
      Repo.aggregate(
        from(n in Notification, where: n.recipient_id == ^user_id and n.tenant_id == ^tenant_id),
        :count
      )

    unread =
      Repo.aggregate(
        from(n in Notification,
          where: n.recipient_id == ^user_id and n.tenant_id == ^tenant_id and is_nil(n.read_at)
        ),
        :count
      )

    %{total: total, unread: unread}
  end

  def unread_count(user_id, tenant_id) do
    Repo.aggregate(
      from(n in Notification,
        where: n.recipient_id == ^user_id and n.tenant_id == ^tenant_id and is_nil(n.read_at)
      ),
      :count
    )
  end

  def mark_read(notification_id, user_id, tenant_id) do
    case Repo.get_by(Notification,
           id: notification_id,
           recipient_id: user_id,
           tenant_id: tenant_id
         ) do
      nil ->
        {:error, :not_found}

      n ->
        if n.read_at do
          {:ok, n}
        else
          n
          |> Ecto.Changeset.change(read_at: DateTime.utc_now() |> DateTime.truncate(:second))
          |> Repo.update()
        end
    end
  end

  def mark_all_read(user_id, tenant_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    {count, _} =
      from(n in Notification,
        where: n.recipient_id == ^user_id and n.tenant_id == ^tenant_id and is_nil(n.read_at)
      )
      |> Repo.update_all(set: [read_at: now, updated_at: now])

    {:ok, count}
  end

  def delete_read_older_than(tenant_id, retention_days) do
    cutoff = DateTime.add(DateTime.utc_now(), -retention_days * 24 * 60 * 60, :second)

    {count, _} =
      from(n in Notification,
        where: n.tenant_id == ^tenant_id and not is_nil(n.read_at) and n.read_at < ^cutoff
      )
      |> Repo.delete_all()

    {:ok, count}
  end
end
