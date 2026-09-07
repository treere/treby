# Pipeline Templates (retired)

## REMOVED Requirements

### Requirement: Create pipeline template
**Reason**: Templates were name-only records with no stage editor; configured
pipelines already serve as reusable models via duplicate and per-job detach.
**Migration**: Settings → Pipeline no longer shows a templates section. Existing
template rows are deleted by migration (they are referenced by nothing).

### Requirement: Manage template stages
**Reason**: Never built — no UI existed to add stages or roles to a template.
**Migration**: None needed; nothing to preserve.

### Requirement: Clone template to create job pipeline
**Reason**: Superseded by per-job pipelines: jobs use the selected/default
pipeline, or receive a dedicated detached clone. The "Or start from a template"
option is removed from the new-job form.
**Migration**: Jobs previously created from a template keep their (already
independent) cloned pipelines, unaffected.

### Requirement: Edit and delete templates
**Reason**: Capability removed along with templates.
**Migration**: None needed.

### Requirement: Template list in settings
**Reason**: Capability removed along with templates.
**Migration**: None needed.
