defmodule Treby.Authorization do
  @moduledoc """
  Action-based workspace authorization — single source of truth for UI and AI agent.

  Roles are presets (`admin` / `recruiter` / `interviewer`); each action key resolves
  to allowed/denied via preset defaults plus per-workspace overrides stored in
  `role_permissions`. Checks fail closed: unknown actions, nil roles, and
  unmapped tools deny.
  """

  @roles ~w(admin recruiter interviewer)

  @groups [
    %{id: :jobs, label: "Jobs"},
    %{id: :candidates, label: "Candidates"},
    %{id: :workflow, label: "Workflow"},
    %{id: :scheduling, label: "Scheduling"},
    %{id: :workspace, label: "Workspace"},
    %{id: :integrations, label: "Integrations"}
  ]

  @actions [
    %{key: :jobs_view, group: :jobs, label: "View jobs"},
    %{key: :jobs_manage, group: :jobs, label: "Create and edit jobs"},
    %{key: :jobs_delete, group: :jobs, label: "Delete jobs"},
    %{key: :candidates_view, group: :candidates, label: "View candidates"},
    %{key: :candidates_create, group: :candidates, label: "Create candidates"},
    %{key: :candidates_update, group: :candidates, label: "Edit candidates"},
    %{key: :candidates_delete, group: :candidates, label: "Delete candidates"},
    %{key: :candidates_merge, group: :candidates, label: "Merge candidates"},
    %{key: :applications_move, group: :workflow, label: "Move applications"},
    %{key: :applications_review, group: :workflow, label: "Review applications"},
    %{key: :notes_manage, group: :workflow, label: "Manage notes"},
    %{key: :interviews_manage, group: :scheduling, label: "Schedule interviews"},
    %{key: :interviews_view, group: :scheduling, label: "View interviews"},
    %{key: :scorecards_submit, group: :scheduling, label: "Submit scorecards"},
    %{key: :scorecards_manage, group: :scheduling, label: "Manage scorecard templates"},
    %{key: :pipeline_view, group: :workflow, label: "View pipelines"},
    %{key: :pipeline_manage, group: :workspace, label: "Manage pipelines"},
    %{key: :pipeline_assign, group: :workspace, label: "Assign stage people"},
    %{key: :team_manage, group: :workspace, label: "Manage team", locked: true},
    %{key: :settings_manage, group: :workspace, label: "Manage settings", locked: true},
    %{key: :fields_manage, group: :workspace, label: "Manage custom fields"},
    %{key: :webhooks_manage, group: :integrations, label: "Manage webhooks"},
    %{key: :audit_view, group: :workspace, label: "View audit log", locked: true},
    %{key: :privacy_manage, group: :workspace, label: "Manage data privacy"},
    %{key: :privacy_view, group: :workspace, label: "View data privacy requests"},
    %{key: :import_csv, group: :integrations, label: "Import CSV"},
    %{key: :comms_send, group: :candidates, label: "Send messages"},
    %{key: :availability_manage, group: :scheduling, label: "Manage availability"},
    %{key: :analytics_view, group: :jobs, label: "View analytics"}
  ]

  @recruiter_defaults MapSet.new([
                        :jobs_view,
                        :jobs_manage,
                        :candidates_view,
                        :candidates_create,
                        :candidates_update,
                        :applications_move,
                        :applications_review,
                        :notes_manage,
                        :interviews_manage,
                        :interviews_view,
                        :scorecards_submit,
                        :pipeline_view,
                        :comms_send,
                        :privacy_view,
                        :availability_manage,
                        :analytics_view
                      ])

  @interviewer_defaults MapSet.new([
                          :jobs_view,
                          :candidates_view,
                          :pipeline_view,
                          :interviews_view,
                          :scorecards_submit,
                          :availability_manage
                        ])

  def roles, do: @roles
  def groups, do: @groups
  def actions, do: @actions
  def action_keys, do: Enum.map(@actions, & &1.key)

  def editable_actions do
    @actions |> Enum.reject(& &1[:locked]) |> Enum.map(& &1.key)
  end

  def locked_actions do
    @actions |> Enum.filter(& &1[:locked]) |> Enum.map(& &1.key)
  end

  @doc "Preset default permission set for a role (MapSet of action atoms)."
  def preset_defaults("admin"), do: MapSet.new(action_keys())
  def preset_defaults(:admin), do: preset_defaults("admin")
  def preset_defaults("recruiter"), do: @recruiter_defaults
  def preset_defaults(:recruiter), do: @recruiter_defaults
  def preset_defaults("interviewer"), do: @interviewer_defaults
  def preset_defaults(:interviewer), do: @interviewer_defaults
  # Legacy role: member behaves like recruiter.
  def preset_defaults("member"), do: @recruiter_defaults
  def preset_defaults(:member), do: @recruiter_defaults
  def preset_defaults(_), do: MapSet.new()

  @doc """
  Effective permission set for a role given workspace overrides.

  Overrides is a map (or keyword) of `%{role => %{action => boolean}}` or a list
  of `%{role: _, action: _, allowed: _}` rows. Unknown actions in overrides are ignored.
  """
  def effective_permissions(role, overrides \\ %{}) do
    base = preset_defaults(normalize_role(role))
    role_key = normalize_role(role)
    valid = MapSet.new(action_keys())

    Enum.reduce(normalize_overrides(overrides, role_key), base, fn {action, allowed}, acc ->
      if action in valid do
        if allowed, do: MapSet.put(acc, action), else: MapSet.delete(acc, action)
      else
        acc
      end
    end)
  end

  @doc "True when the effective set (or role+overrides) allows the action. Fail-closed."
  def can?(%MapSet{} = effective, action) when is_atom(action) do
    action in action_keys() and MapSet.member?(effective, action)
  end

  def can?(_effective, _action), do: false

  def can?(role, action, overrides) when is_atom(action) or is_binary(action) do
    action = normalize_action(action)
    effective_permissions(role, overrides) |> can?(action)
  end

  # Legacy entry-point, delegates to Policy. Use Policy.can?/2 with Actor.from/1 for new code.
  def allowed?(%{} = ctx, action) do
    Treby.Authorization.Policy.can?(Treby.Authorization.Actor.from(ctx), action)
  rescue
    _ -> false
  end

  def allowed?(role, action, overrides) when is_binary(role) or is_atom(role) do
    can?(role, normalize_action(action), overrides)
  end

  def normalize_role(nil), do: nil
  def normalize_role(role) when is_atom(role), do: Atom.to_string(role)
  def normalize_role(role) when is_binary(role), do: role

  @doc "All overrides for a workspace as nested map %{role => %{action_atom => bool}}."
  def overrides_for(nil), do: %{}

  def overrides_for(tenant_id) do
    import Ecto.Query, only: [from: 2]

    Treby.Repo.all(from p in Treby.Authorization.RolePermission, where: p.tenant_id == ^tenant_id)
    |> Enum.reduce(%{}, fn p, acc ->
      action =
        try do
          String.to_existing_atom(p.action)
        rescue
          _ -> nil
        end

      if action, do: put_in(acc, [Access.key(p.role, %{}), action], p.allowed), else: acc
    end)
  end

  @doc "Effective permission set for a membership role in a workspace (DB-backed)."
  def effective_for(nil, _role), do: MapSet.new()
  def effective_for(_tenant_id, "admin"), do: MapSet.new(action_keys())
  def effective_for(_tenant_id, :admin), do: MapSet.new(action_keys())

  def effective_for(tenant_id, role) do
    effective_permissions(role, overrides_for(tenant_id))
  end

  @doc "List override rows for a workspace."
  def list_overrides(tenant_id) do
    import Ecto.Query, only: [from: 2]

    Treby.Repo.all(
      from p in Treby.Authorization.RolePermission,
        where: p.tenant_id == ^tenant_id,
        order_by: [p.role, p.action]
    )
  end

  @doc """
  Create/update a single override cell. Only editable actions and non-admin roles.
  Logs one audit event per save.
  """
  def set_override(tenant_id, role, action, allowed, actor \\ nil) do
    role = normalize_role(role)
    action_str = to_string(normalize_action(action))

    with true <- role in ["recruiter", "interviewer"] || {:error, :invalid_role},
         true <-
           normalize_action(action) in editable_actions() ||
             {:error, :locked_action},
         {:ok, row} <- upsert_override(tenant_id, role, action_str, truthy?(allowed)) do
      Treby.Audit.log_event("role_permission.updated", "role_permission", row.id, %{
        tenant_id: tenant_id,
        actor_id: Treby.Authorization.Actor.id(actor),
        metadata: %{role: role, action: action_str, allowed: truthy?(allowed)}
      })

      {:ok, truthy?(allowed)}
    else
      {:error, _} = err -> err
      false -> {:error, :invalid}
    end
  end

  @doc "Remove an override cell (revert to preset default). Logs audit."
  def reset_override(tenant_id, role, action, actor \\ nil) do
    import Ecto.Query, only: [from: 2]

    role = normalize_role(role)
    action_str = to_string(normalize_action(action))

    row =
      Treby.Repo.get_by(Treby.Authorization.RolePermission,
        tenant_id: tenant_id,
        role: role,
        action: action_str
      )

    {count, _} =
      Treby.Repo.delete_all(
        from p in Treby.Authorization.RolePermission,
          where:
            p.tenant_id == ^tenant_id and p.role == ^role and
              p.action == ^action_str
      )

    if count > 0 && row do
      Treby.Audit.log_event("role_permission.reset", "role_permission", row.id, %{
        tenant_id: tenant_id,
        actor_id: Treby.Authorization.Actor.id(actor),
        metadata: %{role: role, action: action_str}
      })
    end

    {:ok, count}
  end

  defp upsert_override(tenant_id, role, action_str, allowed) do
    case Treby.Repo.get_by(Treby.Authorization.RolePermission,
           tenant_id: tenant_id,
           role: role,
           action: action_str
         ) do
      nil ->
        %Treby.Authorization.RolePermission{}
        |> Treby.Authorization.RolePermission.changeset(%{
          tenant_id: tenant_id,
          role: role,
          action: action_str,
          allowed: allowed
        })
        |> Treby.Repo.insert()

      existing ->
        existing
        |> Treby.Authorization.RolePermission.changeset(%{allowed: allowed})
        |> Treby.Repo.update()
    end
  end

  defp normalize_action(action) when is_atom(action), do: action

  defp normalize_action(action) when is_binary(action) do
    String.to_existing_atom(action)
  rescue
    _ -> :__unknown_action__
  end

  defp normalize_overrides(%MapSet{}, _role), do: []

  defp normalize_overrides(%{} = overrides, role_key) do
    role_map =
      Map.get(overrides, role_key) || Map.get(overrides, safe_atom(role_key)) ||
        Map.get(overrides, :permissions)

    case role_map do
      nil ->
        # Maybe overrides is %{action => bool} directly for this role.
        if Enum.all?(Map.keys(overrides), &is_atom/1) do
          Map.to_list(overrides)
        else
          []
        end

      %MapSet{} = _set ->
        []

      role_map when is_map(role_map) ->
        Map.to_list(role_map)

      _ ->
        []
    end
  end

  defp normalize_overrides(rows, role_key) when is_list(rows) do
    rows
    |> Enum.filter(fn
      %{role: r} -> normalize_role(r) == role_key
      %{"role" => r} -> normalize_role(r) == role_key
      _ -> false
    end)
    |> Enum.map(fn
      %{action: a, allowed: v} -> {normalize_action(a), truthy?(v)}
      %{"action" => a, "allowed" => v} -> {normalize_action(a), truthy?(v)}
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp normalize_overrides(_, _), do: []

  defp truthy?(true), do: true
  defp truthy?(1), do: true
  defp truthy?("true"), do: true
  defp truthy?(_), do: false

  defp safe_atom(nil), do: nil

  defp safe_atom(str) when is_binary(str) do
    String.to_existing_atom(str)
  rescue
    _ -> nil
  end

  defp safe_atom(atom) when is_atom(atom), do: atom

  @tool_actions %{
    Treby.AI.Tools.AddMember => :team_manage,
    Treby.AI.Tools.InviteMember => :team_manage,
    Treby.AI.Tools.RemoveMember => :team_manage,
    Treby.AI.Tools.UpdateMemberRole => :team_manage,
    Treby.AI.Tools.DeleteInvite => :team_manage,
    Treby.AI.Tools.ListInvites => :team_manage,
    Treby.AI.Tools.ListMembers => :jobs_view,
    Treby.AI.Tools.AddPipelineStage => :pipeline_manage,
    Treby.AI.Tools.CreatePipeline => :pipeline_manage,
    Treby.AI.Tools.UpdatePipeline => :pipeline_manage,
    Treby.AI.Tools.DeletePipeline => :pipeline_manage,
    Treby.AI.Tools.UpdatePipelineStage => :pipeline_manage,
    Treby.AI.Tools.DeletePipelineStage => :pipeline_manage,
    Treby.AI.Tools.AssignStagePerson => :pipeline_assign,
    Treby.AI.Tools.UnassignStagePerson => :pipeline_assign,
    Treby.AI.Tools.ListStagePeople => :pipeline_assign,
    Treby.AI.Tools.ListPipelines => :pipeline_view,
    Treby.AI.Tools.ListPipelineStages => :pipeline_view,
    Treby.AI.Tools.BulkDeleteCandidates => :candidates_delete,
    Treby.AI.Tools.DeleteCandidate => :candidates_delete,
    Treby.AI.Tools.MergeCandidates => :candidates_merge,
    Treby.AI.Tools.ListCandidateDuplicates => :candidates_merge,
    Treby.AI.Tools.CreateCandidate => :candidates_create,
    Treby.AI.Tools.GetCandidate => :candidates_view,
    Treby.AI.Tools.ListCandidates => :candidates_view,
    Treby.AI.Tools.UpdateCandidate => :candidates_update,
    Treby.AI.Tools.CreateJob => :jobs_manage,
    Treby.AI.Tools.UpdateJob => :jobs_manage,
    Treby.AI.Tools.DeleteJob => :jobs_delete,
    Treby.AI.Tools.GetJob => :jobs_view,
    Treby.AI.Tools.ListJobs => :jobs_view,
    Treby.AI.Tools.CreateApplication => :applications_move,
    Treby.AI.Tools.MoveApplication => :applications_move,
    Treby.AI.Tools.BulkMoveStage => :applications_move,
    Treby.AI.Tools.ListApplications => :applications_move,
    Treby.AI.Tools.SetApplicationReviewed => :applications_review,
    Treby.AI.Tools.BulkReview => :applications_review,
    Treby.AI.Tools.AddNote => :notes_manage,
    Treby.AI.Tools.UpdateNote => :notes_manage,
    Treby.AI.Tools.DeleteNote => :notes_manage,
    Treby.AI.Tools.ListNotes => :notes_manage,
    Treby.AI.Tools.ScheduleInterview => :interviews_manage,
    Treby.AI.Tools.CancelInterview => :interviews_manage,
    Treby.AI.Tools.CompleteInterview => :interviews_manage,
    Treby.AI.Tools.FindInterviewSubstitutes => :interviews_manage,
    Treby.AI.Tools.CreateCalendarEvent => :interviews_manage,
    Treby.AI.Tools.GetFreeBusy => :interviews_view,
    Treby.AI.Tools.ListCalendarConnections => :interviews_view,
    Treby.AI.Tools.ListInterviews => :interviews_view,
    Treby.AI.Tools.SubmitScorecard => :scorecards_submit,
    Treby.AI.Tools.ListScorecards => :scorecards_submit,
    Treby.AI.Tools.CreateScorecardTemplate => :scorecards_manage,
    Treby.AI.Tools.UpdateScorecardTemplate => :scorecards_manage,
    Treby.AI.Tools.DeleteScorecardTemplate => :scorecards_manage,
    Treby.AI.Tools.ListScorecardTemplates => :scorecards_manage,
    Treby.AI.Tools.CreateAvailabilityRule => :availability_manage,
    Treby.AI.Tools.UpdateAvailabilityRule => :availability_manage,
    Treby.AI.Tools.DeleteAvailabilityRule => :availability_manage,
    Treby.AI.Tools.ListAvailabilityRules => :availability_manage,
    Treby.AI.Tools.SendMessage => :comms_send,
    Treby.AI.Tools.ScheduleMessage => :comms_send,
    Treby.AI.Tools.CancelScheduledMessage => :comms_send,
    Treby.AI.Tools.RescheduleScheduledMessage => :comms_send,
    Treby.AI.Tools.RetryScheduledMessage => :comms_send,
    Treby.AI.Tools.BulkSendMessage => :comms_send,
    Treby.AI.Tools.ListScheduledMessages => :comms_send,
    Treby.AI.Tools.ListEmailTemplates => :comms_send,
    Treby.AI.Tools.CreateEmailTemplate => :settings_manage,
    Treby.AI.Tools.UpdateEmailTemplate => :settings_manage,
    Treby.AI.Tools.DeleteEmailTemplate => :settings_manage,
    Treby.AI.Tools.CreateCustomField => :fields_manage,
    Treby.AI.Tools.UpdateCustomField => :fields_manage,
    Treby.AI.Tools.DeleteCustomField => :fields_manage,
    Treby.AI.Tools.ListCustomFields => :jobs_view,
    Treby.AI.Tools.CreateWebhook => :webhooks_manage,
    Treby.AI.Tools.UpdateWebhook => :webhooks_manage,
    Treby.AI.Tools.DeleteWebhook => :webhooks_manage,
    Treby.AI.Tools.TestWebhook => :webhooks_manage,
    Treby.AI.Tools.ListWebhooks => :webhooks_manage,
    Treby.AI.Tools.ListAuditEvents => :audit_view,
    Treby.AI.Tools.CreateDataRequest => :privacy_view,
    Treby.AI.Tools.ListDataRequests => :privacy_view,
    Treby.AI.Tools.CancelDataRequest => :privacy_manage,
    Treby.AI.Tools.GetCareerPage => :jobs_view,
    Treby.AI.Tools.UpdateCareerPage => :settings_manage,
    Treby.AI.Tools.UpdateSettings => :settings_manage,
    Treby.AI.Tools.SetNotificationPreference => :settings_manage,
    Treby.AI.Tools.GetNotificationPreferences => :jobs_view,
    Treby.AI.Tools.ListNotifications => :jobs_view,
    Treby.AI.Tools.ImportCsv => :import_csv,
    Treby.AI.Tools.PreviewCsvImport => :import_csv,
    Treby.AI.Tools.DashboardSummary => :analytics_view,
    Treby.AI.Tools.FunnelReport => :analytics_view,
    Treby.AI.Tools.JobViewsReport => :analytics_view,
    Treby.AI.Tools.PipelineStats => :analytics_view,
    Treby.AI.Tools.CandidateCompare => :analytics_view,
    Treby.AI.Tools.ListActivities => :analytics_view,
    Treby.AI.Tools.ExplainPage => :jobs_view,
    Treby.AI.Tools.Handoff => :jobs_view,
    Treby.AI.Tools.ProposeFormFill => :jobs_view
  }

  @doc """
  Required action for a tool module. Honors `required_action/0` when exported,
  otherwise falls back to the central registry map. Unknown tools return nil
  (treated as denied downstream — fail-closed).
  """
  def action_for_tool(tool) when is_atom(tool) do
    cond do
      Code.ensure_loaded?(tool) and function_exported?(tool, :required_action, 0) ->
        tool.required_action()

      Map.has_key?(@tool_actions, tool) ->
        Map.fetch!(@tool_actions, tool)

      true ->
        nil
    end
  end

  @doc "All tool modules with a mapped action (for coverage tests)."
  def mapped_tools, do: Map.keys(@tool_actions)

  @doc """
  Permission check for a context actor map (`%{role:, permissions?}`).

  Delegates to `Treby.Authorization.Policy`. Kept for backward compatibility.
  Use `Policy.can?/2` with `Actor.from/1` for new code.
  """
  def can_actor?(nil, _tenant_id, _action), do: false
  def can_actor?(_actor, nil, _action), do: false

  def can_actor?(%{permissions: %MapSet{}} = actor, _tenant_id, action) do
    Treby.Authorization.Policy.can?(actor, action)
  end

  def can_actor?(%{} = actor, tenant_id, action) do
    Treby.Authorization.Policy.can?(Map.put(actor, :tenant_id, tenant_id), action)
  rescue
    _ -> false
  end

  def can_actor?(_actor, _tenant_id, _action), do: false
end
