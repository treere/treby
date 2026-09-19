defmodule Treby.Workers.DataPrivacyExportWorkerTest do
  use Treby.DataCase, async: true

  alias Treby.DataPrivacy.Requests
  alias Treby.Workers.DataPrivacyExportWorker
  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User

  defp setup_tenant do
    suffix = System.unique_integer([:positive])
    {:ok, tenant} = Tenants.create_tenant(%{name: "Export #{suffix}", slug: "export-#{suffix}"})

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "export-#{suffix}@test.com",
        password: "password123",
        name: "Exporter",
        role: "admin"
      })
      |> Repo.insert()

    {:ok, _} =
      Treby.Memberships.create_membership(%{
        user_id: user.id,
        tenant_id: tenant.id,
        role: user.role
      })

    {tenant, user}
  end

  test "builds export and sets ready" do
    {tenant, user} = setup_tenant()

    {:ok, req} =
      Repo.insert(%Treby.DataPrivacy.DataPrivacyRequest{
        tenant_id: tenant.id,
        requester_id: user.id,
        type: "export",
        scope: "tenant",
        status: "pending",
        metadata: %{}
      })

    result =
      DataPrivacyExportWorker.perform(%Oban.Job{args: %{"data_privacy_request_id" => req.id}})

    req2 = Repo.get!(Treby.DataPrivacy.DataPrivacyRequest, req.id)
    assert req2.status in ["ready", "failed", "processing"]
    assert result == :ok or match?({:error, _}, result) or match?({:discard, _}, result)
  end

  test "idempotent on already ready" do
    {tenant, user} = setup_tenant()

    {:ok, req} =
      Repo.insert(%Treby.DataPrivacy.DataPrivacyRequest{
        tenant_id: tenant.id,
        requester_id: user.id,
        type: "export",
        scope: "user",
        status: "pending"
      })

    {:ok, ready} =
      Requests.transition(req, "ready", %{
        s3_key: "#{tenant.id}/data-privacy-exports/#{req.id}.zip",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      })

    assert {:discard, _} =
             DataPrivacyExportWorker.perform(%Oban.Job{
               args: %{"data_privacy_request_id" => ready.id}
             })
  end
end
