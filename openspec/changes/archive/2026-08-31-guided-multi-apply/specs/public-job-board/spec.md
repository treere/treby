## MODIFIED Requirements

### Requirement: Global job board
The system SHALL serve a global public job board at `/careers` showing all visible open positions and, for authenticated candidates, indicate which positions they have already applied to.

#### Scenario: Applied badge on tenant board
- **WHEN** an authenticated candidate for tenant `acme` visits `/acme/careers`
- **THEN** each job they have already applied to shows an "Applied ✓" badge

#### Scenario: Applied badge on global board
- **WHEN** an authenticated candidate for tenant `acme` visits `/careers`
- **THEN** only jobs belonging to `acme` that they have applied to show the badge; jobs from other tenants do not

#### Scenario: Anonymous visitor sees no badge
- **WHEN** an anonymous visitor views `/careers` or `/:tenant_slug/careers`
- **THEN** no applied badges are shown
