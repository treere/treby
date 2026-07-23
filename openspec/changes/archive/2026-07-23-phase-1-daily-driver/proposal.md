## Why

Treby has strong infrastructure (multi-tenant, real-time pipeline, Google Calendar, career pages) but the product layer has critical gaps that prevent daily use. A hiring manager opens the app and sees a welcome message with no data. They can't search candidates, can't edit typos, can't tell what's been reviewed, and can't see who did what. The result: Treby is a prototype you demo, not a tool you use.

## What Changes

- **Actionable dashboard**: Replace the empty welcome page with a command center showing upcoming interviews, stale candidates needing follow-up, pipeline snapshots per job, and weekly stats.
- **Candidate search & filtering**: Add search by name/email and filter by job, stage, and review state to the candidates list.
- **Candidate editing**: Add inline edit form on the candidate profile page (name, email, phone, LinkedIn, custom fields).
- **Application review state**: Add a `reviewed` boolean to applications. Show visual indicators on pipeline cards. One-click toggle. Filter option.
- **Activity timeline**: New `activity_log` table tracking key events (stage moves, notes, interviews, candidate changes). Display as chronological feed on candidate profile.

## Capabilities

### New Capabilities

- `dashboard`: Actionable hiring dashboard with upcoming interviews, stale candidate alerts, pipeline snapshots, and weekly stats.
- `activity-log`: Chronological event log for all hiring actions, displayed on candidate profiles.

### Modified Capabilities

- `candidate-management`: Add search/filter to candidate listing, add inline edit on candidate profile.
- `pipeline`: Add review state (new/viewed) to applications, visual indicators on Kanban cards, filter by review state.

## Impact

- **Schema**: New `activity_log` table. Migration to add `reviewed` boolean to `applications`.
- **Context modules**: New `Treby.Dashboard` and `Treby.Activities` contexts. Extensions to `Treby.Candidates` and `Treby.Pipeline`.
- **LiveViews**: Rewrite `DashboardLive`. Modify `CandidatesLive.Index` (search/filter), `CandidatesLive.Show` (edit + activity feed), `PipelineLive.Index` (review toggle + filter).
- **Templates**: New dashboard layout, candidate search bar, review badges on pipeline cards, activity timeline component.
