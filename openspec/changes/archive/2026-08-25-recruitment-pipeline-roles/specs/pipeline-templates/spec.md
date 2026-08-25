# Pipeline Templates

## Purpose

Allow teams to define reusable pipeline configurations that can be cloned when creating new job openings, eliminating repetitive setup for similar positions.

## ADDED Requirements

### Requirement: Create pipeline template
The system SHALL allow admins to create pipeline templates that define a reusable set of stages with role assignments.

#### Scenario: Create template from scratch
- **WHEN** an admin creates a new pipeline template with a name
- **THEN** the template is saved with `is_template = true`
- **AND** the template appears in the templates list in Settings

#### Scenario: Create template from existing pipeline
- **WHEN** an admin chooses "Save as Template" on an existing pipeline
- **THEN** a new template is created copying all stages, role assignments (examiners, reviewers, advancers), min_examiners, and scorecard template associations from the source pipeline
- **AND** the original pipeline is unchanged

### Requirement: Manage template stages
The system SHALL allow admins to configure stages within a template, including role assignments.

#### Scenario: Add stage to template
- **WHEN** an admin adds a stage to a template
- **THEN** the stage is created with a name, position, color, and stage_type
- **AND** the admin can assign examiners, reviewers, and advancers to the stage

#### Scenario: Configure min_examiners on interview stage
- **WHEN** an admin sets a minimum examiner count on an interview-type stage in a template
- **THEN** the value is saved with the template
- **AND** when the template is cloned, the min_examiners value is carried over

#### Scenario: Assign scorecard template to stage
- **WHEN** an admin associates a scorecard template with a stage in a template
- **THEN** the association is saved
- **AND** when the template is cloned, the scorecard template association is carried over

### Requirement: Clone template to create job pipeline
The system SHALL allow creating a new job by cloning from a template.

#### Scenario: Create job from template
- **WHEN** an admin creates a job and selects a template as the starting point
- **THEN** a new pipeline is created as a copy of the template (stages, role assignments, min_examiners, scorecard template associations)
- **AND** the new pipeline is NOT a template (`is_template = false`)
- **AND** the job is linked to the new pipeline
- **AND** the admin can customize the pipeline after creation

#### Scenario: Create job without template
- **WHEN** an admin creates a job without selecting a template
- **THEN** the job uses the tenant's default pipeline (existing behavior, unchanged)

### Requirement: Edit and delete templates
The system SHALL allow admins to edit and delete pipeline templates.

#### Scenario: Edit template
- **WHEN** an admin renames a template or modifies its stages
- **THEN** the changes are saved
- **AND** existing jobs using pipelines cloned from this template are NOT affected

#### Scenario: Delete template
- **WHEN** an admin deletes a template
- **THEN** the template is removed
- **AND** existing jobs using pipelines cloned from this template are NOT affected

### Requirement: Template list in settings
The system SHALL display all pipeline templates in the Settings page.

#### Scenario: View templates list
- **WHEN** an admin navigates to Settings > Pipeline Templates
- **THEN** a list of all templates for the tenant is displayed
- **AND** each template shows its name, stage count, and whether it has role assignments configured
