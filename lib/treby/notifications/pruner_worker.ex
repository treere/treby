defmodule Treby.Notifications.PrunerWorker do
  use Oban.Worker, queue: :default, max_attempts: 3

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Tenants.Tenant
  alias Treby.Notifications.Inbox
  alias Treby.Notifications

  @impl Oban.Worker
  def perform(_job) do
    tenants = Repo.all(Tenant)

    Enum.each(tenants, fn tenant ->
      days = Notifications.get_retention_days(tenant)
      {:ok, _} = Inbox.delete_read_older_than(tenant.id, days)
    end)

    :ok
  end
end
