# Custom Fields

Add tenant-specific fields to candidates, applications, or jobs — without code changes.

## Configuration

Admins manage fields in **Settings → Fields** (`lib/treby_web/live/settings_live/fields.ex`, `lib/treby/customization/custom_field.ex`):

- Each `CustomField` belongs to a tenant and has an `entity_type` (`candidate`, `application`, `job`), a `key`, `label`, and `field_type` (e.g. text, select)
- `Treby.Customization.list_fields/2` scopes by tenant + entity type; `Customization.create_field/2` enforces admin role

## Where they appear

- **Candidate** fields — on add-candidate and candidate detail
- **Application** fields — on the public apply form (`/:tenant_slug/careers/:job_id/apply`) and inside the candidate/job workspace
- **Job** fields — on job creation/edit, stored as `Job.custom_fields` (map)

Field values are stored as JSON maps on the owning record (e.g. `candidate.custom_fields`) and validated against the defined `CustomField` definitions.

## i18n

Field labels are regular strings; the surrounding UI is translated via Gettext (EN, IT) in `priv/gettext`.
