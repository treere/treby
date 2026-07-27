## Why

After registration, new users land on a dashboard showing four stat cards all at `0` and three "No X." text messages. There is zero guidance on what to do first. Every page in the app is a dead end for new users — empty states show terse gray text with no call-to-action, no illustrations, and no contextual help. Small business owners who are not tech-savvy will have no idea how to get value from the platform, leading to poor activation and early churn.

## What Changes

- **New onboarding checklist component**: A compact, dismissible checklist displayed at the top of the dashboard for users who haven't completed key setup steps. Shows 4 items (create job, add candidate, invite team, customize career page) with a progress bar. Auto-hides when all steps are complete.
- **Smart empty states**: Replace dead-end "No X yet." text across key pages (Dashboard, Jobs, Candidates, Pipeline) with illustrated empty states containing a brief description and a prominent call-to-action button linking to the relevant action.
- **Completion tracking via live state**: No database schema changes. Completion is derived by checking actual tenant data (has jobs? has candidates? has team members besides self? has branding?).
- **Dismiss behavior**: Users can dismiss the checklist per-session or permanently via a user preference.

## Capabilities

### New Capabilities
- `onboarding`: Onboarding checklist component, completion tracking logic, dismiss preferences, and dashboard integration.

### Modified Capabilities
- `dashboard`: Empty states upgraded from plain text to guided CTAs with illustrations. Dashboard mount computes onboarding step completion.

## Impact

- **Files to create**: `onboarding_checklist_component.ex`, corresponding test file
- **Files to modify**: `dashboard_live.ex`, `dashboard_live.html.heex`, `jobs_live/index.html.heex`, `candidates_live/index.html.heex`, `pipeline_live/index.html.heex`
- **No new dependencies, migrations, or schema changes**
- **No API or route changes**
