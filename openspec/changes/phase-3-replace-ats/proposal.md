## Why

Phase 1 made Treby usable for a single hiring manager. Phase 2 made it collaborative for teams. Phase 3 removes the last reasons to keep using spreadsheets or other tools. When switching from an existing workflow, the #1 blocker is data migration (CSV import) and the #1 daily frustration is repetitive actions on multiple candidates (bulk operations). Without these, teams will keep a parallel spreadsheet "just in case."

## What Changes

- **CSV import**: Bring candidate data from spreadsheets into Treby. Map columns to fields, preview before import, deduplicate by email.
- **Bulk operations**: Act on multiple candidates at once — move to stage, mark as reviewed, delete, send email. Select via checkboxes on candidate list and pipeline.
- **Candidate comparison**: Side-by-side view of 2-3 final candidates showing resume, notes, scores, custom fields, and interview feedback.
- **Source tracking**: Know where candidates came from (LinkedIn, Referral, Indeed, Website, Custom). Track source on applications, show breakdown in analytics.
- **Bidirectional email**: Receive candidate replies to interview notifications. View email threads on candidate profile. Reply from within Treby.

## Capabilities

### New Capabilities

- `csv-import`: Upload, parse, map, preview, and import candidate data from CSV files with deduplication.
- `bulk-operations`: Select multiple candidates/applications and perform batch actions (move stage, mark reviewed, delete, send email).
- `candidate-comparison`: Side-by-side comparison view for 2-3 candidates showing all key data.
- `source-tracking`: Track and display where candidates applied from, with configurable source options.
- `bidirectional-email`: Receive, display, and reply to candidate emails within Treby, with full thread history.

### Modified Capabilities

- `analytics`: Add source breakdown chart to analytics page.
- `pipeline`: Add bulk move and bulk review actions to pipeline board.

## Impact

- **Schema**: New `sources` table (or enum), `email_threads` table, `email_messages` table. Migration to add `source` field to `applications`.
- **Context modules**: New `Treby.CsvImport`, `Treby.BulkOperations`, `Treby.Comparison`, `Treby.Sources`, `Treby.EmailThreads`. Extensions to `Treby.Analytics` (source chart), `Treby.Pipeline` (bulk actions).
- **LiveViews**: New `ImportLive` (CSV wizard), new `ComparisonLive`, modified `CandidatesLive.Index` (bulk select), modified `PipelineLive.Index` (bulk actions), modified `AnalyticsLive.Index` (source chart), modified `CandidatesLive.Show` (email thread).
- **Router**: New routes for import, comparison. Modified candidate show route.
- **Dependencies**: `nimble_csv` for CSV parsing (new). Inbound email service (Postmark/SendGrid) for bidirectional email (new).
- **File handling**: CSV upload via LiveView uploads (existing S3 infrastructure).
