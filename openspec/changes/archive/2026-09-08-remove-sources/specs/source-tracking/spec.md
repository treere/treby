## REMOVED Requirements

### Requirement: Configure sources
**Reason**: Candidate source tracking removed — the optional field produced near-empty data (mostly "Unknown") and no actionable insight.
**Migration**: Settings → Sources page, routes, `Treby.Sources` context, and the `sources` table are deleted. No data export; tenants did not rely on the values.

#### Scenario: Default sources
- **WHEN** a new tenant is created
- **THEN** no default sources are seeded and no Sources settings page exists

#### Scenario: Source settings page
- **WHEN** an admin navigates to the former Settings → Sources URL
- **THEN** the route no longer exists

### Requirement: Tag applications with source
**Reason**: Same as above — tagging removed from all creation paths.
**Migration**: The apply-form dropdown, import source selector, manual-creation source, and the `applications.source` column are deleted.

#### Scenario: Source on public application
- **WHEN** a candidate applies via the public career page
- **THEN** the form contains no source question and nothing is recorded

#### Scenario: Source on CSV import
- **WHEN** a user imports candidates via CSV
- **THEN** there is no source selector and imported applications carry no source

#### Scenario: Source on manual creation
- **WHEN** a recruiter manually creates a candidate and adds them to a pipeline
- **THEN** no source is recorded

### Requirement: Display source on candidate/application
**Reason**: Same as above — no source data exists anymore, so all display surfaces are removed.
**Migration**: "Source:" line on candidate detail, "Via ..." on the candidate portal dashboard, and the Analytics source-breakdown card are deleted. Job-view traffic-source analytics (`JobViews`, UTM/referrer based) is unaffected.

#### Scenario: Source on candidate profile
- **WHEN** a user views a candidate profile
- **THEN** applications show no source line

#### Scenario: Source on candidate portal
- **WHEN** a candidate views an application in the portal
- **THEN** the detail shows job title, stage, and application date with no source item
