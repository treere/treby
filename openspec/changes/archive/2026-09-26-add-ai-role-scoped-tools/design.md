## Context

`Treby.AI.Agent` runs a hand-written ReqLLM tool loop. `Treby.AI.Session` classifies each
turn with `Treby.AI.Router` into a domain (`recruiter`, `analytics`, `comms`, `admin`),
then `Treby.AI.Profiles.get/1` returns `%{system_prompt, tools}` for that domain. Read tools
run inline; destructive tools are stored as `pending_confirm` and executed by
`Agent.confirm_tool_run/2` after the user clicks Confirm in `TrebyWeb.AiChatWidget`.

`Treby.AI.Context.build/2` builds `ctx` from `socket.assigns`: `tenant_id`, `user`, `role`
(membership role), page/form state. Tools receive `ctx` but authorize only by tenant.

The app's contexts (`Treby.Candidates`, `Treby.Pipeline`, `Treby.Jobs`, `Treby.Invites`,
`Treby.Scorecards`, `Treby.EmailTemplates`, `Treby.Customization`, `Treby.Accounts`) accept
an optional `actor` and enforce `actor.role != "admin" -> {:error, :unauthorized}`. The UI
authorizes on `Membership.role`; `actor.role` is read from whatever struct is passed.

## Goals / Non-Goals

**Goals**
- The agent can read and act on everything the connected user's role permits, and nothing
  more.
- One authoritative role: the active membership.
- Full staff-facing tool catalog, split read/write.
- Reuse the existing loop, profiles, router, confirm flow, and context actor checks.

**Non-Goals**
- No assistant in the candidate portal.
- No per-field ACL or new policy engine: role is `admin` vs `member`, plus whatever
  per-resource checks existing contexts already enforce via `actor`.
- No schema/migration changes.
- No MCP/API exposure.

## Decisions

### D1 — Membership role is the single source of truth
`ctx.role` already carries `Membership.role`. Add `ctx.actor = %{id: user.id, role: ctx.role}`
and pass `ctx.actor` (never the raw `%User{}`) to context functions as `actor`. This makes
the existing `actor.role != "admin"` checks agree with the UI and removes the
`User.role` / `Membership.role` drift. `ctx.user` (full struct) stays for prompt name/email.

### D2 — Capability declaration per tool
Each tool exports `required_role/0`:

- `:any` — available to every member of the workspace (default).
- `:admin` — admin-only.

`Treby.AI.Tools.required_role(tool)` resolves it, defaulting to `:any` when not exported, so
existing tools need no immediate change.

### D3 — Defense in depth: filter and enforce
- **Expose:** `Profiles.get(domain, role)` (or `Tools.for_role/2`) drops `:admin` tools when
  `role != "admin"`, before `Agent.llm_tools/1` builds the tool list. The model never sees a
  tool it cannot use.
- **Enforce:** `Agent.read_result/2` and `Agent.confirm_tool_run/2` re-check
  `required_role/0` against `ctx.role` and return `{:error, :unauthorized}` on mismatch.
  Enforcement is the real boundary; filtering is UX.

### D4 — Confirmation must carry the role
`AiChatWidget.handle_event("confirm_tool_run", ...)` SHALL build the same role-scoped context
as a normal turn (including `role`/`actor`) and pass it to `Agent.confirm_tool_run/2`, so the
re-check and actor pass-through also apply to confirmed writes.

### D5 — Keep profiles as a selection aid
The full catalog is large; ~100 tools in one prompt degrades selection. Profiles + the LLM
router keep each turn's visible set to roughly a domain. Role filtering then removes admin
tools from a member's set. Profiles are not a security boundary; role is.

### D6 — Read tools stay tenant-scoped
Members can already see all workspace data in the UI, so read tools are tenant-scoped with no
extra per-row filtering in this change. `:admin` read tools (audit log, invites, webhooks,
tenant-wide data-privacy requests, all-users) are role-gated. Per-row rules that already exist
(e.g. pipeline stage advancer) apply through `ctx.actor` on write paths.

`ponytail: read tools return tenant-wide data; add per-row scoping only if a member-level
row filter is actually introduced in the app.`

### D7 — Write tools call contexts with `ctx.actor`
Every write tool passes `ctx.actor` to the context it calls. Where a context has no actor
parameter today (`Memberships.create_membership/1`, `Tenants.update_tenant/2`,
`Jobs.delete_job/1`, `Candidates.create_or_find/2`, `Pipeline.create_application/2`,
`Notes.create_note/2`, `CandidatePortal.send_message/1`), the tool re-checks
`required_role/0` itself before calling. Contexts MAY additionally gain an `actor` parameter
where an admin check is missing, so the UI and AI share one rule.

### D8 — Zoi validates tool inputs centrally
Tool arguments are validated with `Zoi`: `Tools.run/3` decodes each tool's existing JSON
`schema/0` into a Zoi schema (`Zoi.JSONSchema.decode/1`) and parses the args before delegating.
One source of truth, no duplicated per-tool schema, uniform across the whole catalog (input
types, required keys, enums). Unknown keys are tolerated (the JSON schemas do not set
`additionalProperties`). Validation fails open only if a schema cannot be decoded. Outputs are
NOT validated with Zoi: contexts already validate with Ecto changesets and return changeset
errors, so validating structs would add no value. `Zoi` is added as an explicit dependency
(previously only transitive via `req_llm`).

## Full tool catalog

Convention: `R` = read, runs immediately; `W` = write, `destructive?/1 = true`, requires
confirmation. `role` = `any` or `admin`. "context" = existing function the tool delegates to.
`(exists)` = already implemented.

### Jobs
| tool | kind | role | context |
| --- | --- | --- | --- |
| list_jobs (exists) | R | any | Jobs.list_jobs |
| get_job | R | any | Jobs.get_job |
| create_job (exists) | W | any | Jobs.create_job |
| update_job (exists) | W | any | Jobs.update_job |
| delete_job (exists) | W | admin | Jobs.delete_job |

### Candidates
| tool | kind | role | context |
| --- | --- | --- | --- |
| list_candidates (exists) | R | any | Candidates.list_candidates |
| get_candidate (exists) | R | any | Candidates.get_candidate |
| create_candidate (exists) | W | any | Candidates.create_or_find |
| update_candidate (exists) | W | any | Candidates.update_candidate |
| delete_candidate | W | admin | Candidates.delete_candidate |
| merge_candidates | W | admin | Candidates.Merge |
| list_candidate_duplicates | R | admin | Candidates.Duplicates |

### Applications
| tool | kind | role | context |
| --- | --- | --- | --- |
| list_applications | R | any | Pipeline.list_applications_for_job / _for_candidate |
| create_application (exists) | W | any | Pipeline.create_application |
| move_application (exists) | W | any | Pipeline.move_application (advancer via actor) |
| set_application_reviewed | W | any | Pipeline.mark_reviewed / mark_unreviewed |

### Pipeline configuration
| tool | kind | role | context |
| --- | --- | --- | --- |
| list_pipelines | R | any | Pipeline.list_pipelines |
| list_pipeline_stages | R | any | Pipeline.list_pipeline_stages |
| create_pipeline | W | admin | Pipeline.create_pipeline |
| update_pipeline | W | admin | Pipeline.update_pipeline |
| delete_pipeline | W | admin | Pipeline.delete_pipeline |
| add_pipeline_stage (exists) | W | admin | Pipeline.create_pipeline_stage |
| update_pipeline_stage | W | admin | Pipeline.update_pipeline_stage |
| delete_pipeline_stage | W | admin | Pipeline.delete_pipeline_stage |
| list_stage_people | R | any | Pipeline.list_advancers/…/reviewers |
| assign_stage_person | W | admin | Pipeline.assign_advancer/… |
| unassign_stage_person | W | admin | Pipeline.remove_advancer/… |

### Notes
| tool | kind | role | context |
| --- | --- | --- | --- |
| list_notes | R | any | Notes.list_notes_for_application |
| add_note (exists) | W | any | Notes.create_note |
| update_note | W | any | Notes.update_note (author/admin via actor) |
| delete_note | W | any | Notes.delete_note (author/admin via actor) |

### Interviews
| tool | kind | role | context |
| --- | --- | --- | --- |
| list_interviews | R | any | Interviews.list_upcoming_for_tenant / list_for_application |
| schedule_interview | W | any | Interviews.schedule_interview |
| cancel_interview | W | any | Interviews.cancel_interview |
| complete_interview | W | any | Interviews.complete_interview |
| find_interview_substitutes | R | admin | Interviews.find_substitutes |

### Scorecards
| tool | kind | role | context |
| --- | --- | --- | --- |
| list_scorecards | R | any | Scorecards.list_scorecards_for_candidate / _for_interview |
| submit_scorecard | W | any | Scorecards.submit_scorecard |
| list_scorecard_templates | R | any | Scorecards.list_scorecard_templates |
| create_scorecard_template | W | admin | Scorecards.create_scorecard_template |
| update_scorecard_template | W | admin | Scorecards.update_scorecard_template |
| delete_scorecard_template | W | admin | Scorecards.delete_scorecard_template |

### Calendar & availability
| tool | kind | role | context |
| --- | --- | --- | --- |
| list_calendar_connections | R | any | Calendar.list_connections_for_user |
| get_free_busy | R | any | Calendar.get_free_busy |
| create_calendar_event | W | any | Calendar.create_event_with_meet |
| list_availability_rules | R | any | Availability.list_rules_for_user / list_company_rules |
| create_availability_rule | W | any | Availability.create_rule |
| update_availability_rule | W | any | Availability.update_rule |
| delete_availability_rule | W | any | Availability.delete_rule |

### Communications
| tool | kind | role | context |
| --- | --- | --- | --- |
| send_message (exists) | W | any | CandidatePortal.send_message |
| list_scheduled_messages | R | any | ScheduledMessages.list_scheduled / _sent / _failed |
| schedule_message (exists) | W | any | ScheduledMessages.create_scheduled_message |
| cancel_scheduled_message | W | any | ScheduledMessages.cancel |
| reschedule_scheduled_message | W | any | ScheduledMessages.reschedule_delivery! |
| retry_scheduled_message | W | any | ScheduledMessages.retry_failed |
| list_email_templates | R | any | EmailTemplates.list_email_templates |
| create_email_template (exists) | W | admin | EmailTemplates.upsert_email_template |
| update_email_template | W | admin | EmailTemplates.upsert_email_template |
| delete_email_template | W | admin | EmailTemplates.delete_email_template |

### Analytics & page
| tool | kind | role | context |
| --- | --- | --- | --- |
| pipeline_stats (exists) | R | any | Pipeline stats |
| funnel_report (exists) | R | any | JobViews.funnel_for_job |
| job_views_report (exists) | R | any | JobViews summaries |
| candidate_compare (exists) | R | any | Comparison.compare_candidates |
| dashboard_summary | R | any | Dashboard.get_dashboard_data |
| explain_page (exists) | R | any | context page data |

### Team & admin
| tool | kind | role | context |
| --- | --- | --- | --- |
| list_members | R | any | Memberships.list_users_for_tenant |
| list_invites | R | admin | Invites.list_invites |
| invite_member (exists) | W | admin | Invites.create_invite |
| delete_invite | W | admin | Invites.delete_invite |
| add_member (exists) | W | admin | Memberships.create_membership |
| update_member_role | W | admin | Memberships / Accounts.update_user |
| remove_member (exists) | W | admin | Memberships.remove_membership_by_ids |

### Workspace & customization
| tool | kind | role | context |
| --- | --- | --- | --- |
| update_settings (exists) | W | admin | Tenants.update_tenant |
| list_custom_fields | R | any | Customization.list_custom_fields |
| create_custom_field | W | admin | Customization.create_custom_field |
| update_custom_field | W | admin | Customization.update_custom_field |
| delete_custom_field | W | admin | Customization.delete_custom_field |
| get_career_page | R | any | Careers.get_career_page_by_tenant |
| update_career_page | W | admin | Careers.update_career_page |

### Data operations
| tool | kind | role | context |
| --- | --- | --- | --- |
| preview_csv_import | R | any | CsvImport.preview_import |
| import_csv (exists) | W | admin | CsvImport.execute_import |
| bulk_move_stage | W | any | BulkOperations.bulk_move_stage |
| bulk_review | W | any | BulkOperations.bulk_mark_reviewed / _unreviewed |
| bulk_send_message | W | any | BulkOperations.bulk_send_message |
| bulk_delete_candidates | W | admin | BulkOperations.bulk_delete_candidates |

### Notifications, activity, audit
| tool | kind | role | context |
| --- | --- | --- | --- |
| list_notifications | R | any | Notifications inbox |
| get_notification_preferences | R | any | Notifications.notification_preferences |
| set_notification_preference | W | any | Notifications.set_notification_preference |
| list_activities | R | any | Activities.list_events_for_entity |
| list_audit_events | R | admin | Audit.list_events |

### Data privacy & webhooks
| tool | kind | role | context |
| --- | --- | --- | --- |
| list_data_requests | R | any | DataPrivacy.Requests.list_requests |
| create_data_request | W | any | DataPrivacy.Requests.create_request |
| cancel_data_request | W | any | DataPrivacy.Requests.cancel |
| list_webhooks | R | admin | Webhooks.list_subscriptions |
| create_webhook | W | admin | Webhooks.create_subscription |
| update_webhook | W | admin | Webhooks.update_subscription |
| delete_webhook | W | admin | Webhooks.delete_subscription |
| test_webhook | W | admin | Webhooks.test_ping |

### Shared
| tool | kind | role | context |
| --- | --- | --- | --- |
| propose_form_fill (exists) | R | any | page form write |
| handoff (exists) | R | any | Session domain switch |

## Risks / Trade-offs

- [Large catalog weakens tool selection] -> profiles + router per turn; role filter removes
  admin tools for members.
- [Application-layer authz only] -> tools re-check `required_role/0` at run and confirm; the
  context actor is passed for existing per-resource rules. Cross-tenant access stays blocked
  by tenant-scoped queries.
- [Contexts without an actor parameter] -> tools self-check `required_role/0`; optionally add
  `actor` to those contexts so UI and AI share one rule.
- [Read tools tenant-wide] -> accepted; see D6.
- [Two role fields remain in DB] -> the agent uses membership only; a later change could
  deprecate `User.role`. Not in scope.

## Migration Plan

No migrations. Rollback = revert the role filter and new tool modules; existing tools keep
working. Ship in slices: (1) authorization core, (2) role-gate existing tools, (3) add catalog
by domain.
