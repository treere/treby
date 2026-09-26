defmodule Treby.AI.Tools.CatalogToolsTest do
  use Treby.DataCase, async: false

  alias Treby.AI.Tools
  alias Treby.{Repo, Tenants, Memberships, Customization, Webhooks}
  alias Treby.Accounts.User

  defp tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Catalog #{System.unique_integer([:positive])}",
        slug: "catalog-#{System.unique_integer([:positive])}"
      })

    tenant
  end

  defp user(tenant, role) do
    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "catalog-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Catalog User",
        role: "member"
      })
      |> Repo.insert()

    {:ok, _} =
      Memberships.create_membership(%{user_id: user.id, tenant_id: tenant.id, role: role})

    user
  end

  defp ctx(tenant, user, role) do
    %{tenant_id: tenant.id, user: user, role: role, actor: %{id: user.id, role: role}}
  end

  defp application(tenant, admin) do
    Repo.put_tenant_id(tenant.id)

    {:ok, job} =
      Treby.Jobs.create_job(%{
        tenant_id: tenant.id,
        actor_id: admin.id,
        title: "Engineer",
        description: "Build"
      })

    {:ok, candidate} =
      Treby.Candidates.create_or_find(tenant.id, %{
        name: "Jane #{System.unique_integer([:positive])}",
        email: "jane-#{System.unique_integer([:positive])}@x.z"
      })

    pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)

    {:ok, stage} =
      Treby.Pipeline.create_pipeline_stage(
        %{pipeline_id: pipeline_id, name: "New", stage_type: "new"},
        %{id: admin.id, role: "admin"}
      )

    {:ok, app} =
      Treby.Pipeline.create_application(
        %{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: stage.id,
          applied_at: DateTime.utc_now() |> DateTime.to_iso8601()
        },
        []
      )

    app
  end

  test "read tools reject ids from another workspace" do
    t = tenant()
    other = tenant()
    admin = user(t, "admin")
    other_admin = user(other, "admin")
    app = application(t, admin)
    c = ctx(t, admin, "admin")
    other_c = ctx(other, other_admin, "admin")

    {:ok, _note} =
      Treby.Notes.create_note(%{
        "tenant_id" => t.id,
        "application_id" => app.id,
        "author_id" => admin.id,
        "content" => "x",
        "type" => "note"
      })

    assert {:ok, [_]} = Tools.ListNotes.run(%{"application_id" => app.id}, c)

    assert {:error, "application not found"} =
             Tools.ListNotes.run(%{"application_id" => app.id}, other_c)

    assert {:ok, _} = Tools.ListApplications.run(%{"job_id" => app.job_id}, c)

    assert {:error, "job not found"} =
             Tools.ListApplications.run(%{"job_id" => app.job_id}, other_c)

    assert {:ok, _} = Tools.ListInterviews.run(%{"application_id" => app.id}, c)

    assert {:error, "application not found"} =
             Tools.ListInterviews.run(%{"application_id" => app.id}, other_c)

    assert {:ok, _} = Tools.ListScorecards.run(%{"candidate_id" => app.candidate_id}, c)

    assert {:error, "candidate not found"} =
             Tools.ListScorecards.run(%{"candidate_id" => app.candidate_id}, other_c)
  end

  test "bulk review marks applications reviewed" do
    t = tenant()
    admin = user(t, "admin")
    app = application(t, admin)
    c = ctx(t, admin, "admin")

    assert {:ok, %{"updated" => 1}} =
             Tools.BulkReview.run(%{"application_ids" => [app.id], "reviewed" => true}, c)

    assert Treby.Pipeline.get_application(app.id).reviewed
  end

  test "pipeline reads return the workspace pipelines" do
    t = tenant()
    admin = user(t, "admin")

    assert {:ok, pipelines} = Tools.ListPipelines.run(%{}, ctx(t, admin, "admin"))
    assert is_list(pipelines)
    assert Enum.all?(pipelines, &Map.has_key?(&1, "id"))

    assert {:ok, stages} = Tools.ListPipelineStages.run(%{}, ctx(t, admin, "admin"))
    assert is_list(stages)
  end

  test "create_pipeline and delete_pipeline round-trip (admin)" do
    t = tenant()
    admin = user(t, "admin")
    c = ctx(t, admin, "admin")

    assert {:ok, %{"id" => id}} = Tools.CreatePipeline.run(%{"name" => "Backend"}, c)
    assert {:ok, %{"id" => ^id}} = Tools.DeletePipeline.run(%{"pipeline_id" => id}, c)
  end

  test "custom field CRUD and member denial" do
    t = tenant()
    admin = user(t, "admin")
    member = user(t, "member")

    assert {:ok, %{"id" => id}} =
             Tools.CreateCustomField.run(
               %{"name" => "Seniority", "applies_to" => "candidate"},
               ctx(t, admin, "admin")
             )

    assert Customization.get_custom_field!(t.id, id)

    assert {:error, :unauthorized} =
             Tools.CreateCustomField.run(
               %{"name" => "Nope", "applies_to" => "candidate"},
               ctx(t, member, "member")
             )

    assert {:ok, _} = Tools.DeleteCustomField.run(%{"field_id" => id}, ctx(t, admin, "admin"))
  end

  test "list_members and update_member_role" do
    t = tenant()
    admin = user(t, "admin")
    member = user(t, "member")
    c = ctx(t, admin, "admin")

    assert {:ok, members} = Tools.ListMembers.run(%{}, c)
    assert length(members) == 2

    assert {:ok, %{"role" => "admin"}} =
             Tools.UpdateMemberRole.run(%{"user_id" => member.id, "role" => "admin"}, c)

    assert Memberships.get_membership(member.id, t.id).role == "admin"
  end

  test "webhook create, list, delete" do
    t = tenant()
    admin = user(t, "admin")
    c = ctx(t, admin, "admin")

    assert {:ok, %{"id" => id}} =
             Tools.CreateWebhook.run(
               %{"target_url" => "https://example.com/hook", "events" => ["candidate.created"]},
               c
             )

    assert {:ok, subs} = Tools.ListWebhooks.run(%{}, c)
    assert Enum.any?(subs, &(&1["id"] == id))

    assert {:ok, %{"id" => ^id}} = Tools.DeleteWebhook.run(%{"webhook_id" => id}, c)
    assert Webhooks.get_subscription(t.id, id) == nil
  end

  test "notification preferences read and write (admin)" do
    t = tenant()
    admin = user(t, "admin")
    c = ctx(t, admin, "admin")

    assert {:ok, prefs} = Tools.GetNotificationPreferences.run(%{}, c)
    assert is_map(prefs)

    assert {:ok, _} =
             Tools.SetNotificationPreference.run(
               %{"key" => "stage_change_candidate", "email" => false, "inbox" => true},
               c
             )
  end

  test "admin-only reads are denied to members" do
    t = tenant()
    member = user(t, "member")
    c = ctx(t, member, "member")

    assert {:error, :unauthorized} = Tools.run(Tools.ListAuditEvents, %{}, c)
    assert {:error, :unauthorized} = Tools.run(Tools.ListWebhooks, %{}, c)
  end
end
