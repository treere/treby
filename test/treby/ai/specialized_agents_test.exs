defmodule Treby.AI.SpecializedAgentsTest do
  use ExUnit.Case, async: true

  alias Treby.AI.{Context, Profiles, Session, Tools}

  test "every profile tool resolves by name and has a valid schema" do
    for domain <- Profiles.domains() do
      for tool <- Profiles.get(domain).tools do
        assert is_binary(tool.name()), "tool name missing for #{inspect(tool)}"
        assert is_map(tool.schema()), "schema missing for #{tool.name()}"
        assert is_boolean(tool.destructive?()), "destructive? missing for #{tool.name()}"
        assert Tools.get(tool.name()) == tool
      end
    end
  end

  test "Tools.all/0 exposes the new specialized tools plus shared tools" do
    names = Tools.all() |> Enum.map(& &1.name()) |> MapSet.new()

    for expected <-
          [
            "create_candidate",
            "list_candidates",
            "get_candidate",
            "update_candidate",
            "create_application",
            "move_application",
            "add_note",
            "pipeline_stats",
            "job_views_report",
            "candidate_compare",
            "funnel_report",
            "send_message",
            "schedule_message",
            "create_email_template",
            "invite_member",
            "add_member",
            "remove_member",
            "add_pipeline_stage",
            "import_candidates_csv",
            "update_settings",
            "handoff",
            "propose_form_fill"
          ] do
      assert MapSet.member?(names, expected), "missing tool #{expected}"
    end
  end

  test "profiles share the same set of core tools plus their own" do
    recruiter = MapSet.new(Enum.map(Profiles.get(:recruiter).tools, & &1.name()))
    analytics = MapSet.new(Enum.map(Profiles.get(:analytics).tools, & &1.name()))

    refute MapSet.equal?(recruiter, analytics)
    assert MapSet.member?(recruiter, "create_candidate")
    assert MapSet.member?(analytics, "pipeline_stats")
    assert MapSet.member?(recruiter, "handoff")
    assert MapSet.member?(analytics, "handoff")
  end

  test "profiles expose the full catalog and role filtering applies per profile" do
    recruiter = Profiles.get(:recruiter).tools |> Enum.map(& &1.name()) |> MapSet.new()
    analytics = Profiles.get(:analytics).tools |> Enum.map(& &1.name()) |> MapSet.new()
    comms = Profiles.get(:comms).tools |> Enum.map(& &1.name()) |> MapSet.new()
    admin = Profiles.get(:admin).tools |> Enum.map(& &1.name()) |> MapSet.new()

    assert MapSet.member?(recruiter, "list_notes")
    assert MapSet.member?(recruiter, "schedule_interview")
    assert MapSet.member?(recruiter, "list_calendar_connections")
    assert MapSet.member?(analytics, "dashboard_summary")
    assert MapSet.member?(comms, "cancel_scheduled_message")
    assert MapSet.member?(comms, "list_email_templates")
    assert MapSet.member?(recruiter, "delete_candidate")
    assert MapSet.member?(recruiter, "merge_candidates")
    assert MapSet.member?(admin, "bulk_delete_candidates")
    assert MapSet.member?(admin, "list_webhooks")
    assert MapSet.member?(admin, "create_pipeline")

    member_recruiter =
      Profiles.get(:recruiter).tools
      |> Tools.for_role("recruiter")
      |> Enum.map(& &1.name())
      |> MapSet.new()

    refute MapSet.member?(member_recruiter, "delete_candidate")
    refute MapSet.member?(member_recruiter, "merge_candidates")
    refute MapSet.member?(member_recruiter, "create_webhook")
    # Operational interview tools are visible to recruiters.
    assert MapSet.member?(member_recruiter, "find_interview_substitutes")
    assert MapSet.member?(member_recruiter, "create_candidate")
    assert MapSet.member?(member_recruiter, "schedule_interview")

    member_interviewer =
      Profiles.get(:recruiter).tools
      |> Tools.for_role("interviewer")
      |> Enum.map(& &1.name())
      |> MapSet.new()

    assert MapSet.member?(member_interviewer, "list_jobs")
    assert MapSet.member?(member_interviewer, "submit_scorecard")
    refute MapSet.member?(member_interviewer, "create_candidate")
    refute MapSet.member?(member_interviewer, "delete_candidate")
    refute MapSet.member?(member_interviewer, "schedule_interview")
  end

  test "every registered tool maps to exactly one known action" do
    for tool <- Tools.all() do
      action = Treby.Authorization.action_for_tool(tool)
      assert is_atom(action), "tool #{inspect(tool)} has no action mapping"

      assert action in Treby.Authorization.action_keys(),
             "tool #{inspect(tool)} maps to unknown action #{inspect(action)}"
    end
  end

  test "handoff switches the session domain for the next turn" do
    tenant_id = "tenant-handoff"
    user_id = "user-handoff"

    assert {:ok, %{"switched" => true, "domain" => "analytics"}} =
             Tools.Handoff.run(%{"domain" => "analytics"}, %{
               tenant_id: tenant_id,
               user: %{id: user_id}
             })

    assert Session.domain(tenant_id, user_id) == :analytics
  after
    Session.set_domain("tenant-handoff", "user-handoff", :recruiter)
  end

  test "context exposes the current page entity to the model" do
    assigns = %{
      current_user: %{id: 1, name: "Me", email: "me@x.z"},
      current_tenant: %{id: 1},
      current_membership: %{role: "admin"},
      candidate: %Treby.Candidates.Candidate{name: "Jane", email: "jane@x.z"},
      current_path: "/app/candidates/jane"
    }

    ctx = Context.build(assigns)

    assert Map.has_key?(ctx.page_data, "candidate")
    assert ctx.page_data["candidate"][:name] == "Jane"
    assert ctx.system_prompt =~ "Current candidate"
  end
end
