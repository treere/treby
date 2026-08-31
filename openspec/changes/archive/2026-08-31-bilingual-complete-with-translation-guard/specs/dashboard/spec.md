## ADDED Requirements

### Requirement: Dashboard localization (IT/EN)
The system SHALL render all dashboard user-facing text via Gettext so that the dashboard is fully bilingual in Italian and English and respects the user's selected locale. This is the reference implementation for the app-wide bilingual rule.

#### Scenario: Dashboard headings and welcome message in Italian
- **WHEN** a user with the Italian locale visits the dashboard
- **THEN** the page title, welcome message (with interpolated user name), and section headings (Weekly Stats, My Actions, Upcoming Interviews, Stale Candidates, Pipeline Snapshot) are shown in Italian

#### Scenario: My Actions and weekly-stats labels in Italian
- **WHEN** a user with the Italian locale views the dashboard My Actions panel and weekly-stats cards
- **THEN** labels such as "Scorecards to fill", "Waiting on others", "Fill scorecard", "Applications This Week", "Interviews This Week", "Offers This Week", "Hires This Week" are shown in Italian

#### Scenario: Dashboard empty states in Italian
- **WHEN** a user with the Italian locale views an empty dashboard section (no pending scorecards, no upcoming interviews, no stale candidates, no open jobs)
- **THEN** each empty-state title, description, and action label (e.g., "All caught up", "No upcoming interviews", "No open jobs yet", "Create your first job") is shown in Italian

#### Scenario: Dashboard flash messages in Italian
- **WHEN** a user with the Italian locale submits a scorecard from the dashboard
- **THEN** success and error flash messages (e.g., "Scorecard submitted", "Failed to submit scorecard") are shown in Italian

#### Scenario: Activity and interview labels in Italian
- **WHEN** a user with the Italian locale views activity feed entries and upcoming interview rows
- **THEN** activity labels ("New application", "Interview scheduled", "Stage change", etc.) and interviewer placeholders ("To be determined") are shown in Italian

#### Scenario: Dashboard still renders in English for English locale
- **WHEN** a user with the English locale visits the dashboard
- **THEN** all dashboard text is shown in English (no regression)

#### Scenario: Dashboard has no missing Italian translations
- **WHEN** the dashboard localization is complete
- **THEN** every `msgid` introduced for dashboard strings has a non-empty `msgstr` in `priv/gettext/it/LC_MESSAGES/default.po`
- **AND** `mix treby.check_translations` passes for those keys
