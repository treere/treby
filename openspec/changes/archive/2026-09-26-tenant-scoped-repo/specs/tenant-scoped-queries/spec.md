## ADDED Requirements

### Requirement: Queries against tenant-field schemas are auto-scoped

The system SHALL append a `tenant_id` filter to every repository query whose schema carries a `tenant_id` field, using the tenant from the explicit option or the process dictionary.

#### Scenario: Read scoped from process dictionary

- **WHEN** the process tenant is set and a context lists records of a tenant-field schema without options
- **THEN** only records of that tenant are returned

#### Scenario: Explicit option wins

- **WHEN** a call passes an explicit `tenant_id:` option differing from the process tenant
- **THEN** the explicit tenant scopes the query

#### Scenario: Bulk writes scoped

- **WHEN** a bulk `update_all` or `delete_all` targets a tenant-field schema
- **THEN** only rows of the current tenant are affected

### Requirement: Missing tenant fails loudly

The system SHALL raise on any tenant-field query with neither an explicit `tenant_id:` option, nor a process tenant, nor `skip_tenant_id: true`.

#### Scenario: Unscoped query raises

- **WHEN** a tenant-field query runs with no tenant established and no opt-out
- **THEN** an error is raised naming the missing tenant instead of returning cross-tenant rows

#### Scenario: Explicit opt-out bypasses

- **WHEN** a call passes `skip_tenant_id: true`
- **THEN** the query runs unscoped

### Requirement: Field-less schemas pass through

The system SHALL leave queries against schemas without a `tenant_id` field untouched, requiring no tenant and no opt-out.

#### Scenario: Global schema query

- **WHEN** a query targets a schema without a `tenant_id` field and no tenant is established
- **THEN** the query runs normally with no error

### Requirement: Entry points establish the tenant

The system SHALL set the process tenant before repository use in web requests (controllers and LiveViews), Oban workers (from job args), seeds, and test setup.

#### Scenario: LiveView request scoped

- **WHEN** a LiveView mounts through the membership guards
- **THEN** subsequent context queries in that process are scoped to the mounted tenant

#### Scenario: Worker scoped from args

- **WHEN** an Oban worker performs a job carrying a tenant id
- **THEN** its repository calls are scoped to that tenant
