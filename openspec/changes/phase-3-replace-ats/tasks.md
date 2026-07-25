## 1. Dependencies & Configuration

- [x] 1.1 Add `:nimble_csv` dependency to `mix.exs`
- [x] 1.2 Configure LiveView file upload constraints (max 10MB, accept .csv)
- [x] 1.3 Add inbound email webhook endpoint to router (for Postmark/SendGrid)

## 2. Database & Schema — Source Tracking

- [x] 2.1 Create migration to add `source` string field to `applications` table
- [x] 2.2 Create migration to create `sources` table (id, name, tenant_id, is_default, position)
- [x] 2.3 Create `Source` schema with changeset
- [x] 2.4 Seed default sources (LinkedIn, Referral, Indeed, Company Website, Other) for existing tenants
- [x] 2.5 Update `Application` schema to include `source` field
- [x] 2.6 Update `Application` changeset to cast `source`

## 3. Database & Schema — Email Threads

- [x] 3.1 Create migration to create `email_threads` table (id, subject, candidate_id, tenant_id, last_message_at)
- [x] 3.2 Create migration to create `email_messages` table (id, thread_id, direction, from_address, to_address, subject, body, html_body, sent_at, received_at)
- [x] 3.3 Create `EmailThread` schema with changeset
- [x] 3.4 Create `EmailMessage` schema with changeset
- [x] 3.5 Add foreign key constraints and indexes on thread_id, candidate_id

## 4. Database & Schema — Import Log

- [x] 4.1 Create migration to create `import_logs` table (id, file_name, imported_count, skipped_count, error_count, tenant_id, user_id, inserted_at)
- [x] 4.2 Create `ImportLog` schema with changeset

## 5. Context — Source Tracking

- [x] 5.1 Create `Treby.Sources` context module
- [x] 5.2 Implement `list_sources/1` (by tenant, ordered by position)
- [x] 5.3 Implement `create_source/2`
- [x] 5.4 Implement `update_source/2` (rename — cascades to applications)
- [x] 5.5 Implement `delete_source/1` (re-tag applications as "Other")
- [x] 5.6 Implement `default_source/1` (returns "Other" source for tenant)

## 6. Context — CSV Import

- [x] 6.1 Create `Treby.CsvImport` context module
- [x] 6.2 Implement `parse_csv/1` — read CSV binary, return rows + headers using nimble_csv
- [x] 6.3 Implement `auto_detect_mapping/2` — match headers to field names (case-insensitive)
- [x] 6.4 Implement `validate_row/2` — check required fields, email format
- [x] 6.5 Implement `preview_import/3` — first 10 rows with mapping applied, duplicate detection
- [x] 6.6 Implement `execute_import/4` — import all valid rows in a single transaction
- [x] 6.7 Implement deduplication logic (skip rows with existing email in tenant)
- [x] 6.8 Implement `log_import/3` — create ImportLog record with counts

## 7. Context — Bulk Operations

- [x] 7.1 Create `Treby.BulkOperations` context module
- [x] 7.2 Implement `bulk_move_stage/3` — move multiple application_ids to a stage in one transaction
- [x] 7.3 Implement `bulk_mark_reviewed/2` — mark multiple applications as reviewed
- [x] 7.4 Implement `bulk_mark_unreviewed/2` — mark multiple applications as unreviewed
- [x] 7.5 Implement `bulk_delete_candidates/2` — delete multiple candidates and cascade (in one transaction)
- [x] 7.6 Implement `bulk_send_email/3` — send personalized email to multiple candidates

## 8. Context — Email Threads

- [x] 8.1 Create `Treby.EmailThreads` context module
- [x] 8.2 Implement `list_threads_for_candidate/1` (ordered by last_message_at desc)
- [x] 8.3 Implement `get_thread!/1` with preloaded messages
- [x] 8.4 Implement `create_inbound_email/2` — parse webhook payload, match to candidate, create/append thread
- [x] 8.5 Implement `send_reply/3` — send via Swoosh, create outbound message, update thread timestamp
- [x] 8.6 Implement threading headers (In-Reply-To, References) for outbound emails

## 9. Context — Candidate Comparison

- [x] 9.1 Create `Treby.Comparison` context module
- [x] 9.2 Implement `compare_candidates/1` — fetch full data for 2-3 candidates (contacts, apps, notes, scorecards, interviews, custom fields)

## 10. LiveViews — CSV Import Wizard

- [x] 10.1 Create `ImportLive` LiveView with step wizard (Upload → Map → Preview → Import)
- [x] 10.2 Step 1: File upload using LiveView uploads (accept .csv, max 10MB)
- [x] 10.3 Step 2: Column mapping UI — auto-detected mapping with manual override dropdowns
- [x] 10.4 Step 3: Preview table — first 10 rows, duplicate highlighting, validation errors
- [x] 10.5 Step 4: Import confirmation with job/stage/source selection, then execute
- [x] 10.6 Import summary page showing counts and import log
- [x] 10.7 Add route `/app/import` to router

## 11. LiveViews — Bulk Operations

- [x] 11.1 Add checkboxes to `CandidatesLive.Index` candidate table
- [x] 11.2 Add checkboxes to `PipelineLive.Index` candidate cards
- [x] 11.3 Create floating action bar component (appears when items selected)
- [x] 11.4 Add "Move to Stage" action with stage dropdown
- [x] 11.5 Add "Mark as Reviewed" / "Mark as New" actions
- [x] 11.6 Add "Delete" action with confirmation dialog
- [x] 11.7 Add "Send Email" action with inline composer
- [x] 11.8 Implement `handle_event` handlers for all bulk actions
- [x] 11.9 Show bulk action summary (e.g., "5 candidates moved to Interview")

## 12. LiveViews — Candidate Comparison

- [x] 12.1 Add "Compare" checkbox/button to `CandidatesLive.Index` and `PipelineLive.Index`
- [x] 12.2 Enforce selection limit (max 3) with error message
- [x] 12.3 Create `ComparisonLive` LiveView with side-by-side grid
- [x] 12.4 Display contact info, custom fields, applications per candidate column
- [x] 12.5 Display notes with ratings per candidate
- [x] 12.6 Display scorecards per candidate
- [x] 12.7 Display interview history per candidate
- [x] 12.8 Add resume link per candidate
- [x] 12.9 Highlight highest scores per criterion
- [x] 12.10 Add route `/app/compare` to router

## 13. LiveViews — Source Settings

- [x] 13.1 Create `SettingsLive.Sources` LiveView with source list and CRUD
- [x] 13.2 Add source list with edit/delete actions
- [x] 13.3 Add "Add Source" form
- [x] 13.4 Add route `/app/settings/sources` to router
- [x] 13.5 Update settings hub page with link to Sources

## 14. LiveViews — Source on Application Forms

- [x] 14.1 Add "How did you hear about us?" dropdown to `CareersLive.Apply` (public form)
- [x] 14.2 Populate dropdown from tenant's configured sources
- [x] 14.3 Add source selection to CSV import wizard (Step 4)
- [x] 14.4 Show source on `CandidatesLive.Show` per application

## 15. LiveViews — Source Analytics

- [x] 15.1 Add source breakdown chart to `AnalyticsLive.Index`
- [x] 15.2 Query source counts and stage progression for chart data
- [x] 15.3 Filter source chart by pipeline (using Phase 2 pipeline selector)

## 16. LiveViews — Email Threads

- [x] 16.1 Add email thread section to `CandidatesLive.Show`
- [x] 16.2 Display thread list with subject, date, message count
- [x] 16.3 Display thread detail with chronological messages
- [x] 16.4 Style inbound vs outbound messages differently
- [x] 16.5 Add "Reply" button with inline composer
- [x] 16.6 Implement reply send via EmailThreads context

## 17. Inbound Email Webhook

- [x] 17.1 Create `EmailWebhookController` for POST `/webhooks/inbound`
- [x] 17.2 Implement Postmark/SendGrid payload parsing
- [x] 17.3 Match inbound email to candidate by sender address
- [x] 17.4 Create or append to email thread
- [x] 17.5 Return 200 OK to webhook (non-blocking)
- [ ] 17.6 Add webhook verification (signature validation)

## 18. Router & Navigation

- [x] 18.1 Add `/app/import` route
- [x] 18.2 Add `/app/compare` route
- [x] 18.3 Add `/app/settings/sources` route
- [x] 18.4 Add `/webhooks/inbound` route (public, no auth)
- [x] 18.5 Update nav/settings hub with new links

## 19. Cleanup & Verification

- [ ] 19.1 Run `mix precommit` and fix any issues
- [ ] 19.2 Test CSV upload, column mapping, preview, and import flow
- [ ] 19.3 Test CSV deduplication (existing email skipped)
- [ ] 19.4 Test CSV validation errors (missing email, bad format)
- [ ] 19.5 Test bulk move on candidate list and pipeline
- [ ] 19.6 Test bulk mark reviewed/unreviewed
- [ ] 19.7 Test bulk delete with confirmation
- [ ] 19.8 Test bulk send email
- [ ] 19.9 Test candidate comparison view with 2 and 3 candidates
- [ ] 19.10 Test source settings CRUD
- [ ] 19.11 Test source on public application form
- [ ] 19.12 Test source breakdown in analytics
- [ ] 19.13 Test inbound email webhook (mock Postmark payload)
- [ ] 19.14 Test email thread display and reply flow
