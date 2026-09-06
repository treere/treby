## MODIFIED Requirements

### Requirement: Public career page
The system SHALL serve a public career page at `/:tenant_slug/careers`. The page SHALL include a consistent public header that contains a brand/homepage link (navigates to `/`) on the left and the theme toggle plus language switcher on the right, rendered with `dark:` overrides so the header remains ≥4.5:1 in dark mode. The header SHALL be visible regardless of theme or locale.

#### Scenario: Career page loads
- **WHEN** a visitor navigates to `/:tenant_slug/careers`
- **THEN** the page displays the tenant's logo, name, and open job listings
- **AND** a header bar with homepage link (Treby/tenant brand → `/`) and theme + language controls is visible at the top

#### Scenario: Closed jobs hidden
- **WHEN** the career page loads
- **THEN** only jobs with status "open" are displayed

### Requirement: Job detail on career page
The system SHALL show job details on the career page including company branding. The detail surface at `/:tenant_slug/careers/:job_id` SHALL include the same public header (homepage link + theme + language) as the listing page, and the "Back to all positions" link and any fallback ghost buttons SHALL have `dark:` overrides to remain legible in dark mode and SHALL be wrapped with `gettext` so they translate correctly (no English/Italian mix).

#### Scenario: Click job listing
- **WHEN** a visitor clicks on a job listing
- **THEN** the full job description, salary range, company logo, company name, company description, and "Apply" button are shown

#### Scenario: Closed job detail
- **WHEN** a visitor navigates to a job detail page for a closed job
- **THEN** the page displays "This position is no longer available" with a link back to the career page

#### Scenario: Job detail header and back link in dark Italian
- **WHEN** a visitor with locale IT opens `http://localhost:4000/acme/careers/8dec86b3-7584-47f0-b9f6-7af6625a55da` in dark mode
- **THEN** the header with homepage/brand + theme + language is visible and contrast-compliant, the "← Back to all positions" link is shown in Italian ("← Torna a tutte le posizioni" or the `msgstr` for that `msgid`) with `dark:text-*` contrast, and no English/Italian mix appears

