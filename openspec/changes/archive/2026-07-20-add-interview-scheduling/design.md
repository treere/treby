## Context

Treby is a multi-tenant ATS built with Phoenix LiveView. It currently handles job postings, candidate management, a Kanban pipeline with real-time updates, notes/feedback, custom fields, career pages, and basic analytics. There is no interview scheduling capability — the "Interview" pipeline stage is just a label with no associated logic.

This change adds native interview scheduling with Google Calendar integration, closing the gap between candidate pipeline management and actual interview execution. The integration uses Google Calendar API v3 for free/busy queries and event creation with auto-generated Google Meet links.

## Goals / Non-Goals

**Goals:**
- Connect team members' Google calendars to see real availability
- Compute available interview slots by combining availability rules with calendar free/busy data
- Schedule interviews with auto-generated Google Meet links
- Let candidates self-schedule via a public booking page
- Keep tokens encrypted at rest using Cloak
- Refresh tokens lazily (on API call, not background job)

**Non-Goals:**
- Microsoft Outlook/Calendar integration (future)
- Interview panels / multiple interviewers per slot (future)
- Bidirectional calendar sync / webhooks (future)
- Onsite or phone interview types (video only for now)
- Interviewer load balancing or daily limits (future)
- AI-assisted scheduling (future)

## Decisions

### D1: Cloak for encryption (not Fernet)

**Decision:** Use `cloak_ecto ~> 1.3.0` with AES-256-GCM for encrypting OAuth tokens at rest.

**Alternatives considered:**
- `fernet_ecto` — Stale (last updated 2019), zero dependants, uses weaker AES-128-CBC, no key rotation support
- Manual `:crypto` encrypt/decrypt — No Ecto integration, no tagged ciphertexts, no key rotation

**Rationale:** Cloak is the Elixir standard (7.8M downloads). Provides transparent Ecto type integration, tagged ciphertexts for key rotation, and HMAC-based searchable encrypted fields if needed later.

### D2: Lazy token refresh (not background job)

**Decision:** Check token expiry on every Google API call. If expired or expiring within 5 minutes, refresh using the stored refresh token before making the call.

**Alternatives considered:**
- Oban scheduled job — Persistent, survives crashes, but overkill for ~5-10 connected calendars
- GenServer with `Process.send_after` — In-memory timer, dies on crash, no persistence needed for this scale

**Rationale:** Token lifetime is 1 hour. Scheduling actions are interactive and infrequent (user-initiated). The refresh call itself takes <500ms. A background job adds complexity with no practical benefit at this scale.

### D3: Google-only calendar provider (not abstracted)

**Decision:** Build Google Calendar integration directly without a provider abstraction layer.

**Alternatives considered:**
- Calendar provider behaviour (Google + Microsoft behind a common interface) — Adds ~20% overhead, enables future Outlook support
- Third-party unified API (Nylas, Cronofy) — External dependency, cost, data residency concerns

**Rationale:** This is a startup tool. Google Calendar covers the vast majority of use cases. If Outlook support is needed later, the Google-specific code can be refactored into a behaviour at that point. Premature abstraction adds complexity without immediate value.

### D4: Slot computation in application code (not Google Calendar)

**Decision:** Generate available slots by combining local availability rules with Google FreeBusy data in Elixir, rather than relying solely on Google's availability features.

**Rationale:** Google's FreeBusy API returns raw busy periods — it doesn't know about our availability rules, buffer times, or slot granularity. The computation pipeline is:
1. Get availability rules for the user → generate candidate time slots
2. Query Google FreeBusy → get busy periods
3. Subtract busy periods and buffers from candidate slots
4. Return available slots

This gives us full control over scheduling logic independent of the calendar provider.

### D5: Public booking tokens (not signed URLs)

**Decision:** Generate opaque random tokens stored in the database for candidate self-scheduling links, with expiry and single-use semantics.

**Alternatives considered:**
- Signed JWTs — Stateless, no DB lookup, but can't revoke or track usage
- Time-limited magic links — Similar to tokens but harder to manage lifecycle

**Rationale:** Tokens allow revocation, usage tracking, and expiry enforcement. The DB lookup cost is negligible for a startup tool. Tokens are consistent with the existing invite token pattern in the codebase.

### D6: Video-only meeting type

**Decision:** All interviews are video calls with auto-generated Google Meet links. No phone or onsite types.

**Rationale:** Simplifies the MVP. Google Meet links are auto-provisioned via the Calendar API's `conferenceData` feature. Phone/onsite can be added later as a simple enum expansion.

## Risks / Trade-offs

**[Google API rate limits]** → FreeBusy has a limit of 100 queries per 100 seconds per project. At startup scale (~5-10 users), this is not a concern. Mitigation: cache FreeBusy results for 5 minutes within a scheduling session.

**[Token security]** → OAuth tokens stored encrypted in the database. If the database is compromised and the encryption key is also leaked, tokens are exposed. Mitigation: encryption key stored as env var, never in code. Cloak supports key rotation if a key is compromised.

**[Calendar event deletion on cancel]** → When an interview is cancelled, we delete the Google Calendar event. If the Google API is down at that moment, the event persists on Google. Mitigation: mark interview as cancelled in Treby regardless; calendar cleanup is best-effort.

**[Timezone edge cases]** → Availability rules use a single timezone per user. Candidates booking from different timezones see slots in their local time, but the underlying computation uses the interviewer's timezone. Mitigation: display all times in the viewer's local timezone (auto-detected via browser), store everything as UTC.

**[Single interviewer per slot]** → No panel scheduling in this iteration. Each interview event links to one interviewer. Mitigation: acceptable for MVP; panel support is explicitly a non-goal.

## Migration Plan

1. Add new dependencies (`cloak_ecto`, `goth`) and config
2. Run migrations for new tables (`calendar_connections`, `availability_rules`, `interview_events`, `booking_tokens`)
3. Deploy — existing functionality unchanged, new features are additive
4. No data migration needed — new tables are empty on deploy
5. Rollback: drop new tables, remove deps (no existing data affected)

## Open Questions

- Should interview duration be fixed (e.g. 30min) or configurable per scheduling event? → Suggest fixed 30min for MVP, configurable later
- Should we cache FreeBusy results within a scheduling session to reduce API calls? → Suggest yes, 5-minute TTL cache
