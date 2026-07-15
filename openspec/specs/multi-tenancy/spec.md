# Multi-Tenancy

## Purpose

Isolate data between tenants and support both multi-tenant and single-tenant self-hosted deployments.

## Requirements

### Requirement: Tenant data isolation
The system SHALL isolate data between tenants using tenant_id on all tables.

#### Scenario: Tenant created with default settings
- **WHEN** a new tenant is created
- **THEN** it has a unique slug, name, and empty settings JSONB

#### Scenario: Query scoping
- **WHEN** a user queries any resource (jobs, candidates, applications)
- **THEN** only resources belonging to their tenant are returned

### Requirement: Tenant slug identification
The system SHALL identify tenants by slug in public URLs.

#### Scenario: Career page URL
- **WHEN** a visitor navigates to `/:tenant_slug/careers`
- **THEN** the system loads the tenant matching that slug

#### Scenario: Invalid slug
- **WHEN** a visitor navigates to `/:invalid_slug/careers`
- **THEN** the system returns a 404 page

### Requirement: Default pipeline stages
The system SHALL create default pipeline stages when a tenant is created.

#### Scenario: New tenant gets default stages
- **WHEN** a new tenant is created
- **THEN** it has pipeline stages: New, Screen, Phone Screen, Interview, Offer, Hired (in that order)

### Requirement: Self-hosted single tenant mode
The system SHALL support single-tenant deployments for self-hosted usage.

#### Scenario: Self-hosted installation
- **WHEN** the application is deployed as self-hosted
- **THEN** a default tenant is created on first run
- **AND** all routes work without tenant slug prefix (or with the default slug)
