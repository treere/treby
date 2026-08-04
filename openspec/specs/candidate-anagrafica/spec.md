# Candidate Anagrafica

## Purpose

Separate the master candidate profile (the internal reference) from immutable per-application snapshots of the data each applicant submitted.

## Requirements

### Requirement: Master candidate profile
The system SHALL maintain a single master anagrafica per candidate (name, email, phone, LinkedIn URL, custom fields) that serves as the internal reference for identity, deduplication, and email communication. The master SHALL be editable without affecting historical application data.

#### Scenario: Edit master profile
- **WHEN** a user edits the master candidate profile
- **THEN** the candidate record is updated
- **AND** no existing application's anagrafica snapshot is modified

#### Scenario: Master is the dedup identity
- **WHEN** the system checks for an existing candidate
- **THEN** it uses the master email (case-insensitive) within the tenant as the identity key

### Requirement: Per-application anagrafica snapshot
The system SHALL store on each application the contact data the applicant entered at submission time (name, email, phone, LinkedIn URL) as an immutable snapshot.

#### Scenario: Snapshot on career page application
- **WHEN** a candidate submits the career page form with name, email, and phone
- **THEN** the application stores an anagrafica snapshot containing exactly the submitted values
- **AND** the values are stored even if the candidate already exists and the master differs

#### Scenario: Snapshot on CSV import
- **WHEN** a candidate is imported via CSV with a job and stage
- **THEN** the created application stores the imported row's contact data as its anagrafica snapshot

#### Scenario: Snapshot on manual application
- **WHEN** a user manually creates an application for a candidate
- **THEN** the application stores the candidate's current master data as its anagrafica snapshot

#### Scenario: Re-application preserves entered data
- **WHEN** an existing candidate applies to another position with different phone or name data
- **THEN** the new application stores the newly entered values in its snapshot
- **AND** the master profile is not overwritten

### Requirement: Snapshot immutability
The system SHALL treat application anagrafica snapshots as read-only after creation. No update to a candidate, job, or pipeline SHALL rewrite an existing snapshot.

#### Scenario: Master edit does not rewrite snapshots
- **WHEN** a user edits the candidate's phone on the master profile
- **THEN** each application continues to display the phone submitted with that application

### Requirement: Snapshot display on candidate profile
The system SHALL display each application's anagrafica snapshot on the candidate profile page. When a snapshot differs from the current master, the system SHALL indicate the data as submitted with that application.

#### Scenario: Snapshot differs from master
- **WHEN** an application's snapshot phone differs from the master phone
- **THEN** the application card shows the submitted value labeled as submitted for that application
- **AND** the master value remains the profile's primary display

#### Scenario: Snapshot matches master
- **WHEN** an application's snapshot equals the master data
- **THEN** the application card shows the master values without additional labeling

### Requirement: Backfill existing applications
The system SHALL backfill anagrafica snapshots for applications created before this capability existed, using the candidate's current master data.

#### Scenario: Existing applications get snapshots
- **WHEN** the system is upgraded and existing applications have no snapshot
- **THEN** each application is populated with its candidate's current name, email, phone, and LinkedIn URL
