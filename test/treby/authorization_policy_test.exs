defmodule Treby.Authorization.PolicyTest do
  use Treby.DataCase, async: true

  alias Treby.Authorization.{Actor, Policy}
  alias Treby.Authorization
  alias Treby.{Accounts, Memberships, Tenants}

  test "allowed action passes via MapSet and actor parity" do
    effective = Authorization.effective_permissions("recruiter", %{})
    actor = %{id: 1, role: "recruiter", permissions: effective}

    assert Policy.can?(effective, :candidates_create)
    assert Policy.can?(actor, :candidates_create)
    refute Policy.can?(effective, :team_manage)
    refute Policy.can?(actor, :team_manage)
  end

  test "fail-closed on nil and unknown" do
    effective = Authorization.effective_permissions("recruiter", %{})

    refute Policy.can?(nil, :jobs_view)
    refute Policy.can?(effective, nil)
    refute Policy.can?(effective, :no_such_action)
    refute Policy.can?(effective, "no_such_action")
    refute Policy.can?(%{id: 1, role: nil, permissions: MapSet.new()}, :jobs_view)
    refute Policy.can?(%{id: 1, permissions: "nope"}, :jobs_view)
    assert Policy.can?(effective, "jobs_view") == Policy.can?(effective, :jobs_view)
  end

  test "string vs atom role resolves identically" do
    tenant = %{id: 123}
    membership_str = %{role: "recruiter", tenant_id: 123, user_id: 1}
    membership_atom = %{role: :recruiter, tenant_id: 123, user_id: 1}

    a1 = Actor.from(%{current_membership: membership_str, current_tenant: tenant})
    a2 = Actor.from(%{current_membership: membership_atom, current_tenant: tenant})

    assert a1.permissions == a2.permissions
    assert Policy.can?(a1, :candidates_create)
    assert Policy.can?(a2, :candidates_create)
  end

  test "socket and assigns agree, missing tenant denies" do
    tenant = %{id: 999, slug: "acme"}
    membership = %{role: "recruiter", tenant_id: 999, user_id: 42}
    user = %{id: 42}
    assigns = %{current_membership: membership, current_tenant: tenant, current_user: user}

    from_assigns = Actor.from(assigns)
    from_socket = Actor.from(%{assigns: assigns})

    assert from_assigns == from_socket
    assert from_assigns.id == 42

    missing = Actor.from(%{current_membership: %{role: "recruiter"}, current_tenant: nil})
    refute Policy.can?(missing, :jobs_view)
  end

  test "ctx with precomputed permissions wins" do
    perms = Authorization.effective_permissions("interviewer", %{})
    actor = Actor.from(%{role: "interviewer", tenant_id: 1, permissions: perms, user_id: 7})
    assert actor.permissions == perms
    assert Policy.can?(actor, :scorecards_submit)
    refute Policy.can?(actor, :applications_move)
  end

  test "revoked override denies on rebuilt actor (confirm re-check)" do
    suffix = System.unique_integer([:positive])

    {:ok, tenant} =
      Tenants.create_tenant(%{name: "Revoke #{suffix}", slug: "revoke-#{suffix}"})

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> Accounts.User.changeset(%{
        email: "revoke-#{suffix}@test.com",
        password: "password123",
        name: "Revoke",
        role: "admin"
      })
      |> Treby.Repo.insert()

    {:ok, membership} =
      Memberships.create_membership(%{
        user_id: user.id,
        tenant_id: tenant.id,
        role: "recruiter"
      })

    refute Policy.can?(
             Actor.from(%{
               current_membership: membership,
               current_tenant: tenant,
               current_user: user
             }),
             :pipeline_manage
           )

    {:ok, _} = Authorization.set_override(tenant.id, "recruiter", :pipeline_manage, true, nil)

    assert Policy.can?(
             Actor.from(%{
               current_membership: membership,
               current_tenant: tenant,
               current_user: user
             }),
             :pipeline_manage
           )

    {:ok, 1} = Authorization.reset_override(tenant.id, "recruiter", :pipeline_manage, nil)

    refute Policy.can?(
             Actor.from(%{
               current_membership: membership,
               current_tenant: tenant,
               current_user: user
             }),
             :pipeline_manage
           )
  end
end
