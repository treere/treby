defmodule Treby.Workers.DataPrivacyErasureWorkerTest do
  use Treby.DataCase, async: true

  alias Treby.DataPrivacy.Requests
  alias Treby.Workers.DataPrivacyErasureWorker
  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User

  defp setup_tenant do
    suffix = System.unique_integer([:positive])
    {:ok, tenant} = Tenants.create_tenant(%{name: "Erasure #{suffix}", slug: "erasure-#{suffix}"})

    {:ok, admin} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "erasure-admin-#{suffix}@test.com",
        password: "password123",
        name: "Admin",
        role: "admin"
      })
      |> Repo.insert()

    {:ok, _} =
      Treby.Memberships.create_membership(%{
        user_id: admin.id,
        tenant_id: tenant.id,
        role: admin.role
      })

    {:ok, member} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "erasure-member-#{suffix}@test.com",
        password: "password123",
        name: "Member",
        role: "member"
      })
      |> Repo.insert()

    {:ok, _} =
      Treby.Memberships.create_membership(%{
        user_id: member.id,
        tenant_id: tenant.id,
        role: member.role
      })

    {tenant, admin, member}
  end

  test "anonymizes user scope" do
    {tenant, _admin, member} = setup_tenant()
    grace = DateTime.add(DateTime.utc_now(), -10, :second) |> DateTime.to_iso8601()
    # Insert directly to avoid inline Oban execution
    {:ok, req} =
      Repo.insert(%Treby.DataPrivacy.DataPrivacyRequest{
        tenant_id: tenant.id,
        requester_id: member.id,
        type: "erasure",
        scope: "user",
        status: "pending",
        metadata: %{"grace_until" => grace}
      })

    assert :ok =
             DataPrivacyErasureWorker.perform(%Oban.Job{
               args: %{"data_privacy_request_id" => req.id}
             })

    updated = Repo.get!(User, member.id)
    assert String.starts_with?(updated.email, "deleted+")
    req2 = Repo.get!(Treby.DataPrivacy.DataPrivacyRequest, req.id)
    assert req2.status == "completed"
  end

  test "rejects last admin erasure" do
    {tenant, admin, _member} = setup_tenant()

    Repo.delete_all(
      from m in Treby.Memberships.Membership,
        where: m.tenant_id == ^tenant.id and m.role == "member"
    )

    grace = DateTime.add(DateTime.utc_now(), -10, :second) |> DateTime.to_iso8601()

    {:ok, req} =
      Repo.insert(%Treby.DataPrivacy.DataPrivacyRequest{
        tenant_id: tenant.id,
        requester_id: admin.id,
        type: "erasure",
        scope: "user",
        status: "pending",
        metadata: %{"grace_until" => grace}
      })

    result =
      DataPrivacyErasureWorker.perform(%Oban.Job{args: %{"data_privacy_request_id" => req.id}})

    assert match?({:error, _}, result)
  end

  test "discards cancelled" do
    {tenant, _admin, member} = setup_tenant()

    {:ok, req} =
      Repo.insert(%Treby.DataPrivacy.DataPrivacyRequest{
        tenant_id: tenant.id,
        requester_id: member.id,
        type: "erasure",
        scope: "user",
        status: "pending",
        metadata: %{
          "grace_until" =>
            DateTime.add(DateTime.utc_now(), 3600, :second) |> DateTime.to_iso8601()
        }
      })

    {:ok, cancelled} = Requests.cancel(req)

    assert {:discard, _} =
             DataPrivacyErasureWorker.perform(%Oban.Job{
               args: %{"data_privacy_request_id" => cancelled.id}
             })
  end

  test "anonymizes tenant scope" do
    {tenant, admin, _member} = setup_tenant()
    # Create candidate with resume_url mocked via direct insert
    {:ok, candidate} =
      %Treby.Candidates.Candidate{
        tenant_id: tenant.id,
        name: "John Doe",
        email: "john-#{System.unique_integer([:positive])}@test.com"
      }
      |> Treby.Candidates.Candidate.changeset(%{
        name: "John Doe",
        email: "john-#{System.unique_integer([:positive])}@test.com"
      })
      |> Repo.insert()

    # Ensure candidate email is not yet deleted
    refute String.starts_with?(candidate.email, "deleted+")
    grace = DateTime.add(DateTime.utc_now(), -10, :second) |> DateTime.to_iso8601()

    {:ok, req} =
      Repo.insert(%Treby.DataPrivacy.DataPrivacyRequest{
        tenant_id: tenant.id,
        requester_id: admin.id,
        type: "erasure",
        scope: "tenant",
        status: "pending",
        metadata: %{"grace_until" => grace}
      })

    assert :ok =
             DataPrivacyErasureWorker.perform(%Oban.Job{
               args: %{"data_privacy_request_id" => req.id}
             })

    updated = Repo.get!(Treby.Candidates.Candidate, candidate.id)
    assert String.starts_with?(updated.email, "deleted+")
    assert updated.phone == nil
    req2 = Repo.get!(Treby.DataPrivacy.DataPrivacyRequest, req.id)
    assert req2.status == "completed"
  end
end
