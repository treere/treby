# Design: Modular Calendar & Meeting Providers

## Context

Today the scheduling flow is Google-bound end to end:

- `ScheduleLive.Index` lists only users with a `calendar_connections` row (`Calendar.list_connected_users/1`), so internal scheduling is impossible without Google.
- Both booking paths call `Calendar.create_event_with_meet/3` on the primary examiner; if that examiner is not connected, booking fails with `:not_connected`.
- Slot availability intersects availability rules with Google `free_busy` only. Treby's own `interview_events` are **never** treated as busy, so an examiner with no Google connection can be double-booked by two concurrent flows. `compute_slots/5` (single examiner) fails closed on Google errors while `compute_overlapping_slots/5` swallows them — inconsistent.
- A single `google_event_id` is stored on the interview; cancellation deletes it with `scheduled_by_id`'s token even though the event was created with the examiner's token (latent bug).
- `SlotCache` is a local ETS table caching **final slot computations** (TTL 5 min), which creates a double-booking window.

The app already runs a BEAM cluster (`dns_cluster`), so a node-distributed cache needs no external service.

## Goals / Non-Goals

**Goals:**
- Decouple availability and meeting creation from Google; Google becomes one provider among several.
- An always-active internal calendar that prevents double-booking on Treby-scheduled interviews.
- Aggregate busy from all connected providers in parallel, fail-closed on provider errors.
- Jitsi meeting links when Google is not available; a single calendar event with all examiners + candidate as attendees when it is.
- A distributed in-cluster cache for external provider responses.
- Schema changes to make provider identity explicit.

**Non-Goals:**
- Implementing additional providers (Outlook, Zoom, CalDAV). The abstraction must make them drop-in, but only Google + Jitsi + internal are built here.
- A visual weekly availability grid in settings (future polish).
- DB-level exclusion constraints as a final anti-double-booking guarantee (application-level check + fresh internal busy are sufficient for now).
- Multi-event creation across several external providers (deferred until a second event-capable provider exists).

## Decisions

### 1. Two orthogonal provider abstractions

`CalendarProvider` (presence: busy + event lifecycle) and `MeetingProvider` (video link generation). Google is the only provider that couples them (Meet arrives bundled with event creation); Jitsi proves a meeting link can exist with zero calendar presence.

- **Alternative considered:** a single provider behaviour. Rejected — it would make "no Google" equal "no Jitsi", reproducing today's bug.
- **Alternative considered:** meeting link as a field on CalendarProvider. Rejected; Jitsi has no calendar and would have to fake an empty one.

### 2. Treby's internal calendar is a CalendarProvider, always active

`Treby.Calendar.Providers.Treby` implements `fetch_busy/3` by querying `interview_events` joined with `event_examiners` for the user, `status: "scheduled"`, overlapping the requested range. It is unconditionally part of the aggregation; external providers are added only when a connection exists.

### 3. Busy aggregation across all connected providers, fail-closed

```
busy(user, from, to) =
    TrebyProvider.fetch_busy(user)                 # always
  ++ Enum.flat_map(connected(user), fn p ->       # every external connection
       Provider.fetch_busy(p, from, to)
     end)
```

If any connected external provider returns `{:error, _}`, slot computation returns an error and the scheduling page blocks (consistent in both single- and multi-examiner paths). `:not_connected` simply means "provider absent" and contributes nothing. This is the user's explicit "blocco" decision.

- **Alternative considered:** degrade to rules-only on error (current overlapping behavior). Rejected — risks double-booking during an outage; a connected-but-broken calendar is treated as a hard conflict source.

### 4. Meeting resolution

```
resolve_meeting(examiners) →
  if any required examiner is Google-connected →
    {:calendar_event, owner: first_connected_examiner, conference: :google_meet}
  else →
    {:meeting_url, provider: :jitsi}
```

- `{:calendar_event, ...}`: create **one** Google Calendar event on the **owner examiner's** calendar with `conferenceData` (Meet); attendees = **all examiners' emails + candidate email**; `sendUpdates: "none"` (appears on everyone's calendar, no email spam). The Meet link becomes `video_conf_url`; `provider_event_id`, `calendar_provider = "google"`, `calendar_owner_id` are stored.
- `{:meeting_url, :jitsi}`: pure URL `https://meet.jit.si/treby-<tenant-slug>-<uuid>`; `video_conf_url` stored, no external event.

The owner is the **first connected required examiner** (deterministic); the scheduler's own user is never used as owner. Other connected providers participate in presence only until a second event-capable provider exists.

### 5. Event ownership fixes cancellation

Store `calendar_owner_id` on `interview_events`. `cancel_interview/1` deletes the event using the **owner's** connection + `provider_event_id`, not `scheduled_by_id`'s. Backfill existing rows from the first `event_examiner` (the historical event creator).

### 6. Schema migration

```
calendar_connections
  google_email  → provider_email         (rename, keep value)
  unique(tenant_id, user_id)             → unique(tenant_id, user_id, provider)

interview_events
  google_event_id → provider_event_id    (rename, keep value)
  + calendar_provider  :string           (backfill "google" where provider_event_id not null)
  + calendar_owner_id  :user_id          (backfill first event_examiner)
```

One `provider` column already exists on `calendar_connections` (default "google"); it becomes meaningful.

### 7. Distributed cache: single-owner ETS via `:global`

Replace `SlotCache` with `ProviderCache`, an ETS table owned by a single GenServer registered via `:global`. Every node starts the GenServer; the first to `:global.register_name` wins; standby processes monitor the name and re-register on failover. Clients resolve the owner with `:global.whereis_name/1`.

Cache granularity changes from **final slots** to **external provider responses**:

```
key = {provider, user_id, from, to}   value = busy periods   TTL = 5 min
```

- Rationale: internal busy is always re-read fresh from the DB, so final slots are never stale and **no invalidation on booking/cancel is needed**; the cache only dedupes external API calls across nodes.
- **Alternative considered:** Redis/Redix. Rejected per user decision — BEAM-internal is preferred; a single-owner ETS cache is dependency-free and loss is benign.
- **Alternative considered:** Mnesia replicas. Rejected — more operational baggage than a volatile TTL cache warrants.

### 8. Internal scheduler picker

`ScheduleLive.Index` lists examiners with **availability rules** (replacing `Calendar.list_connected_users/1`), shows a connection badge per examiner, and computes slots through the shared aggregation. The candidate portal keeps using stage-eligible examiners.

### 9. UI de-Googling

"Join Google Meet" → dynamic label from `video_conf_url` provider; "Video (Google Meet)" → provider-agnostic ("Video" with the link).

## Risks / Trade-offs

- **Single-owner cache is a mild SPOF** → cache is an optimization only; loss/failover just triggers a few extra external API calls; the DB remains the source of truth for internal busy.
- **`:global` behavior under network partitions** (split-brain, temporary duplicate owners) → acceptable because a stale cache entry only affects external busy and expires within 5 min.
- **Jitsi rooms are open URLs** → unguessable UUID + tenant prefix is the only protection today; no lobby/auth on `meet.jit.si`. Mitigation: document that room names are secrets; a self-hosted Jitsi with lobby is a future option.
- **Fail-closed means one broken provider blocks scheduling for that user** → accepted per user decision; surface a clear, specific error (which provider failed) rather than a generic failure.
- **Backfill of `calendar_owner_id` may be imperfect for historical rows** → worst case, cancellation of a legacy interview fails to delete a stale Google event; re-run is idempotent (404 treated as success).
- **Multiple connections per user (new unique constraint) conflicts with existing assumption of one row per user** → migration must drop the old unique index; existing code paths that assume one connection must be audited (`Calendar.get_connection/1` becomes "get connection for provider").

## Migration Plan

1. Migration 1 — `calendar_connections`: rename `google_email` → `provider_email`; drop unique `(tenant_id, user_id)`; add unique `(tenant_id, user_id, provider)`.
2. Migration 2 — `interview_events`: rename `google_event_id` → `provider_event_id`; add `calendar_provider`, `calendar_owner_id`; backfill `calendar_provider = "google"` where `provider_event_id` is not null; backfill `calendar_owner_id` from the first `event_examiner`.
3. Deploy provider behaviour modules + resolver + internal provider + cache behind the new code paths; keep old Google module functions for reference until tests pass.
4. Switch booking flows and scheduling UIs to the resolver.
5. Rollback: revert schema (recreate old columns/constraints) and code paths; data loss is limited to the two renamed/added columns.

## Open Questions

- None blocking. Owner selection ("first connected required examiner") is a soft decision open to change once a second event-capable provider arrives.