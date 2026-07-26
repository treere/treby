## Context

Treby is a multi-tenant ATS built with Phoenix LiveView. Phases 1-2 added a dashboard, search, editing, review state, activity logging, RBAC, scorecards, and email templates. The app is now usable for daily hiring but still has friction points that keep teams tied to spreadsheets:

- No way to import existing candidate data from CSVs
- Every candidate action is one-at-a-time (move, review, delete)
- No way to compare final candidates side-by-side
- No source tracking (where did candidates come from?)
- Email is one-way (system → human); can't see or reply to candidate responses

The target is small businesses and startups switching from spreadsheets or basic tools.

## Goals / Non-Goals

**Goals:**
- Make data migration trivial (CSV import with mapping and dedup)
- Eliminate repetitive one-at-a-time actions (bulk operations)
- Support structured decision-making (candidate comparison)
- Provide sourcing insights (source tracking + analytics)
- Enable two-way communication without leaving Treby (bidirectional email)

**Non-Goals:**
- Job board integrations (LinkedIn, Indeed APIs) — expensive partnerships, low ROI
- Resume parsing/extraction — AI-heavy, unreliable, out of scope
- Email open/click tracking — requires tracking pixels, complex email service integration
- Multi-channel communication (SMS, WhatsApp) — email is sufficient
- Advanced deduplication (fuzzy name matching) — exact email match is enough

## Decisions

### 1. CSV import: LiveView upload → S3 → parse → map → preview → import

**Decision**: Four-step wizard: Upload → Map Columns → Preview → Import. CSV is uploaded via LiveView file uploads to S3, parsed server-side with `nimble_csv`, mapped to fields via a column-mapping UI, previewed in a table, then imported in a single transaction.

**Rationale**: The wizard pattern is familiar and reduces errors. Previewing before import prevents bad data. S3 storage means the CSV is preserved for re-import if needed.

**Alternatives considered**:
- Direct paste (no file upload): Limited to small datasets, no persistence
- Background job parsing: Overkill — CSVs are small (hundreds of rows, not millions)
- Client-side parsing: Security risk — can't validate server-side

### 2. CSV column mapping

**Decision**: Auto-detect columns by header name matching (case-insensitive substring match against field names). Show a mapping UI where users can override auto-detection. Support mapping to: name, email, phone, linkedin_url, custom fields.

**Rationale**: Auto-detection handles 80% of cases (most CSVs have sensible headers). Manual override handles the rest. Custom fields are included because that's why people have spreadsheets.

### 3. CSV deduplication

**Decision**: Deduplicate by email address (exact match, case-insensitive). If a candidate with the same email exists in the tenant, skip the import row and report it in the summary.

**Rationale**: Email is the natural unique identifier for candidates. Same as the public application flow (`find_or_create_candidate`). Fuzzy matching (name similarity) is unreliable and out of scope.

### 4. Bulk operations: checkbox selection + batch actions

**Decision**: Add checkboxes to candidate list and pipeline cards. Track selected IDs in socket assign. Show a floating action bar when items are selected with actions: Move to Stage, Mark Reviewed, Delete, Send Email. Execute in a single transaction.

**Rationale**: Checkbox + floating bar is the standard pattern (GitHub, Notion, Linear). Single transaction ensures atomicity — either all succeed or all fail.

**Alternatives considered**:
- Select-all-only: Too coarse — users need to pick specific candidates
- Per-card action menus: Doesn't scale to bulk
- Background job for bulk: Overkill for hundreds of items

### 5. Bulk move to stage

**Decision**: When "Move to Stage" is selected, show a dropdown of available stages. On confirm, move all selected applications to that stage in a single transaction. If email templates are configured for the target stage type, show the confirmation dialog (from Phase 2) with "Send to all" / "Skip all" options.

**Rationale**: Reuses the Phase 2 email template flow. "Send to all" / "Skip all" avoids per-candidate confirmation for bulk moves.

### 6. Candidate comparison: side-by-side panel

**Decision**: "Compare" button on candidate cards. Select 2-3 candidates. New LiveView or modal showing a comparison grid with columns per candidate. Data includes: contact info, custom fields, all notes/ratings, scorecards, interview history, application stages.

**Rationale**: 2-3 candidates is the typical final-round comparison. More than 3 would be unreadable on a single screen. Side-by-side is the natural mental model.

### 7. Source tracking: application-level field

**Decision**: Add a `source` field to `applications` (not candidates). Sources are configurable per tenant in Settings with presets: LinkedIn, Referral, Indeed, Company Website, Other. Custom sources can be added. The source is set during application creation (public form dropdown or CSV import mapping).

**Rationale**: Source is per-application, not per-candidate (someone might apply from LinkedIn for one job and Referral for another). Presets cover 90% of cases; custom sources handle the rest.

### 8. Source on public application form

**Decision**: Add an optional "How did you hear about us?" dropdown to the public application form. Options are the tenant's configured sources. Optional because not all candidates will know or care.

**Rationale**: Capturing source at application time is the most accurate. Post-hoc tagging is unreliable.

### 9. Bidirectional email: inbound webhook + thread storage

**Decision**: Use Postmark or SendGrid inbound email parsing. When a reply comes in to an interview notification, parse the webhook payload and store the email in a new `email_threads` / `email_messages` table. Display threads on the candidate profile. Reply via Swoosh.

**Rationale**: Postmark and SendGrid are the standard inbound email services for Phoenix apps. Webhook-based parsing is reliable and well-documented. Storing threads in the DB enables search and display.

**Alternatives considered**:
- IMAP polling: unreliable, complex, requires credentials per tenant
- AI-powered email extraction: overkill, privacy concerns
- No inbound, just outbound: defeats the purpose of "bidirectional"

### 10. Email thread storage schema

**Decision**: Two tables:
- `email_threads`: id, subject, candidate_id, tenant_id, last_message_at
- `email_messages`: id, thread_id, direction (inbound/outbound), from_address, to_address, body, html_body, sent_at, received_at

**Rationale**: Thread-per-candidate-per-subject is the natural grouping. Separating threads from messages allows efficient listing (threads) and detailed viewing (messages).

### 11. Reply flow

**Decision**: "Reply" button on email thread in candidate profile. Opens an inline composer with the previous message quoted. Send via Swoosh. New message is appended to the existing thread.

**Rationale**: Inline reply keeps the user in context. Quoting the previous message provides context for the candidate.

## Risks / Trade-offs

- **[Risk] CSV encoding issues**: Different OS/Excel exports use different encodings (UTF-8, Latin-1, CP1252). Mitigated by trying UTF-8 first, falling back to Latin-1. `nimble_csv` handles this.
- **[Risk] Large CSV imports blocking the BEAM**: Mitigated by limiting CSV size (10MB, same as resume uploads) and processing synchronously for small files. Can add Task.async_stream for larger files later.
- **[Risk] Inbound email parsing failures**: Malformed emails, missing headers, spam. Mitigated by defensive parsing and logging. Failed parses are logged but don't crash the system.
- **[Risk] Bulk operations on large selections**: Selecting 100+ candidates and moving them all could be slow. Mitigated by transaction batching and progress feedback in the UI.
- **[Trade-off] No resume parsing**: CSV import requires manual column mapping. Automated resume parsing (extracting name, email, skills from PDFs) would be magical but is AI-heavy and unreliable.
- **[Trade-off] Source is per-application, not per-candidate**: Can't easily see "all sources for this candidate across applications." Acceptable — source analytics are per-pipeline, not per-candidate.
- **[Trade-off] No email open tracking**: Can't tell if candidates read stage-based emails. Would require tracking pixels and email service webhooks. Out of scope.
- **[Dependency] `nimble_csv`**: New dependency for CSV parsing. Lightweight, well-maintained, Elixir-native. No compiled code.
- **[Dependency] Inbound email service**: Postmark or SendGrid. Requires account setup and DNS configuration. Can be deferred — bidirectional email is the last feature in Phase 3.
