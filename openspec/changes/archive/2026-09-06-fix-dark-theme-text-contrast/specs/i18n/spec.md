## MODIFIED Requirements

### Requirement: Full-application bilingual UI (IT/EN)
The system SHALL render every user-facing string in the authenticated application (layouts, navigation, dashboard, jobs, candidates, pipeline, interviews, analytics, settings, candidate portal, career pages, empty states, flash messages) via Gettext (`gettext`/`ngettext`), so that switching the locale between Italian and English translates the entire interface. This explicitly includes the public careers pages (`/careers`, `/:tenant_slug/careers`, `/:tenant_slug/careers/:job_id` and `/:tenant_slug/careers/:job_id/apply`): navigation links like "Back to all positions" / "View other positions", headings like "This position is no longer available" / "Position not found", and action labels like "Apply Now" and "Already applied — View status" SHALL be wrapped with `gettext` and have Italian `msgstr` entries so no English/Italian mix appears regardless of theme (light or dark). Theme switching SHALL NOT affect locale.

#### Scenario: Dashboard renders in Italian
- **WHEN** a user with the Italian locale visits `/app` (dashboard)
- **THEN** all dashboard headings, labels, weekly-stats captions, My Actions headings, empty-state titles/descriptions, and onboarding checklist items are shown in Italian

#### Scenario: Dashboard renders in English
- **WHEN** a user with the English locale visits `/app`
- **THEN** the same dashboard content is shown in English

#### Scenario: No hardcoded user-facing strings outside Gettext
- **WHEN** the codebase is scanned for user-facing literals in `lib/treby_web/live/**` and `lib/treby_web/components/**`
- **THEN** no heading, label, button text, empty-state copy, or flash message is emitted as a raw string literal outside a `gettext` call (excluding brand names and technical identifiers)

#### Scenario: Locale switch persists and applies globally
- **WHEN** a user changes the language in Settings → Language and navigates to any page (dashboard, jobs, candidates, interviews)
- **THEN** the selected locale is applied on every subsequent request until changed again

#### Scenario: Careers pages are fully translated in Italian
- **WHEN** a user with the Italian locale visits `/:tenant_slug/careers/:job_id` (e.g., `/acme/careers/8dec86b3-7584-47f0-b9f6-7af6625a55da`) in either light or dark mode
- **THEN** "← Back to all positions", "View other positions", "This position is no longer available", "Position not found", "The job you're looking for has been closed or removed.", "The job you're looking for doesn't exist or has been removed.", "Apply Now", and "Already applied — View status" are all shown in Italian, with no English/Italian mix

#### Scenario: Theme does not affect translation
- **WHEN** the same Italian user toggles between light, dark, and system themes on `/:tenant_slug/careers/:job_id`
- **THEN** the language of all strings remains Italian and no string reverts to English in dark mode

