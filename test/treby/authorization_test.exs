defmodule Treby.AuthorizationTest do
  use Treby.DataCase, async: true

  alias Treby.Authorization
  alias Treby.{Tenants, Memberships}
  alias Treby.Accounts.User

  defp tenant_with_role(role) do
    suffix = System.unique_integer([:positive])

    {:ok, tenant} =
      Tenants.create_tenant(%{name: "Auth #{suffix}", slug: "auth-#{suffix}"})

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "auth-#{suffix}@test.com",
        password: "password123",
        name: "Auth",
        role: "admin"
      })
      |> Treby.Repo.insert()

    {:ok, _} =
      Memberships.create_membership(%{user_id: user.id, tenant_id: tenant.id, role: role})

    {tenant, user}
  end

  describe "preset defaults" do
    test "admin has every action" do
      effective = Authorization.effective_permissions("admin", %{})

      for action <- Authorization.action_keys() do
        assert Authorization.can?(effective, action), "admin missing #{action}"
      end
    end

    test "recruiter has operational defaults but not admin gates" do
      effective = Authorization.effective_permissions("recruiter", %{})

      assert Authorization.can?(effective, :candidates_create)
      assert Authorization.can?(effective, :applications_move)
      assert Authorization.can?(effective, :interviews_manage)
      assert Authorization.can?(effective, :comms_send)
      assert Authorization.can?(effective, :privacy_view)
      refute Authorization.can?(effective, :privacy_manage)
      refute Authorization.can?(effective, :candidates_delete)
      refute Authorization.can?(effective, :team_manage)
      refute Authorization.can?(effective, :audit_view)
      refute Authorization.can?(effective, :webhooks_manage)
    end

    test "interviewer is scoped to view plus scorecards and availability" do
      effective = Authorization.effective_permissions("interviewer", %{})

      assert Authorization.can?(effective, :jobs_view)
      assert Authorization.can?(effective, :candidates_view)
      assert Authorization.can?(effective, :scorecards_submit)
      assert Authorization.can?(effective, :availability_manage)
      refute Authorization.can?(effective, :privacy_view)
      refute Authorization.can?(effective, :privacy_manage)
      refute Authorization.can?(effective, :candidates_create)
      refute Authorization.can?(effective, :applications_move)
      refute Authorization.can?(effective, :notes_manage)
    end

    test "legacy member resolves like recruiter" do
      assert Authorization.effective_permissions("member", %{}) ==
               Authorization.effective_permissions("recruiter", %{})
    end
  end

  describe "fail-closed behavior" do
    test "unknown action denies" do
      effective = Authorization.effective_permissions("admin", %{})
      refute Authorization.can?(effective, :no_such_action)
    end

    test "nil role denies everything" do
      effective = Authorization.effective_permissions(nil, %{})

      for action <- Authorization.action_keys() do
        refute Authorization.can?(effective, action)
      end
    end

    test "unknown role denies everything" do
      effective = Authorization.effective_permissions("owner", %{})
      refute Authorization.can?(effective, :jobs_view)
    end

    test "unmapped tool resolves to nil and denies" do
      assert Authorization.action_for_tool(NotAModule) == nil
    end
  end

  describe "workspace overrides" do
    test "override grants a denied action for one role only" do
      {tenant, _} = tenant_with_role("recruiter")

      refute Authorization.can?(
               Authorization.effective_for(tenant.id, "recruiter"),
               :pipeline_manage
             )

      {:ok, _} =
        Authorization.set_override(tenant.id, "recruiter", :pipeline_manage, true, nil)

      assert Authorization.can?(
               Authorization.effective_for(tenant.id, "recruiter"),
               :pipeline_manage
             )

      refute Authorization.can?(
               Authorization.effective_for(tenant.id, "interviewer"),
               :pipeline_manage
             )
    end

    test "override can revoke a default grant" do
      {tenant, _} = tenant_with_role("recruiter")

      assert Authorization.can?(
               Authorization.effective_for(tenant.id, "recruiter"),
               :comms_send
             )

      {:ok, _} =
        Authorization.set_override(tenant.id, "recruiter", :comms_send, false, nil)

      refute Authorization.can?(
               Authorization.effective_for(tenant.id, "recruiter"),
               :comms_send
             )
    end

    test "overrides are tenant-isolated" do
      {tenant_a, _} = tenant_with_role("recruiter")
      {tenant_b, _} = tenant_with_role("recruiter")

      {:ok, _} =
        Authorization.set_override(tenant_a.id, "recruiter", :pipeline_manage, true, nil)

      assert Authorization.can?(
               Authorization.effective_for(tenant_a.id, "recruiter"),
               :pipeline_manage
             )

      refute Authorization.can?(
               Authorization.effective_for(tenant_b.id, "recruiter"),
               :pipeline_manage
             )
    end

    test "locked actions and admin role cannot be overridden" do
      {tenant, _} = tenant_with_role("recruiter")

      assert {:error, :locked_action} =
               Authorization.set_override(tenant.id, "recruiter", :team_manage, true, nil)

      assert {:error, :invalid_role} =
               Authorization.set_override(tenant.id, "admin", :pipeline_manage, true, nil)
    end

    test "reset reverts to preset default" do
      {tenant, _} = tenant_with_role("recruiter")

      {:ok, _} =
        Authorization.set_override(tenant.id, "recruiter", :pipeline_manage, true, nil)

      {:ok, 1} = Authorization.reset_override(tenant.id, "recruiter", :pipeline_manage, nil)

      refute Authorization.can?(
               Authorization.effective_for(tenant.id, "recruiter"),
               :pipeline_manage
             )
    end
  end

  describe "tool coverage" do
    test "every registered tool maps to a known action" do
      for tool <- Treby.AI.Tools.all() do
        action = Authorization.action_for_tool(tool)
        assert is_atom(action), "tool #{inspect(tool)} has no action"
        assert action in Authorization.action_keys()
      end
    end

    test "denied tools are hidden from the model, not just blocked" do
      tools = Treby.AI.Tools.all()
      recruiter_tools = Treby.AI.Tools.for_role(tools, "recruiter") |> Enum.map(& &1.name())

      refute "delete_candidate" in recruiter_tools
      refute "create_webhook" in recruiter_tools
      assert "create_candidate" in recruiter_tools
      assert "schedule_interview" in recruiter_tools
    end

    test "run re-checks at execution time" do
      {tenant, user} = tenant_with_role("interviewer")

      ctx = %{
        tenant_id: tenant.id,
        user: user,
        user_id: user.id,
        role: "interviewer",
        actor: %{id: user.id, role: "interviewer"}
      }

      assert {:error, :unauthorized} =
               Treby.AI.Tools.authorize(Treby.AI.Tools.DeleteCandidate, ctx)

      assert {:error, :unauthorized} =
               Treby.AI.Tools.run(Treby.AI.Tools.DeleteCandidate, %{"id" => "x"}, ctx)
    end
  end
end
