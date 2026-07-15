# Notes

## Purpose

Allow team members to add and manage notes on applications, including interview feedback.

## Requirements

### Requirement: Add note to application
The system SHALL allow team members to add notes to applications.

#### Scenario: Add general note
- **WHEN** a user adds a note to an application
- **THEN** the note is saved with content, author, and timestamp

#### Scenario: Add interview feedback
- **WHEN** a user adds an interview feedback note with rating
- **THEN** the note is saved with type "interview_feedback" and rating (1-5)

### Requirement: View notes on application
The system SHALL display all notes for an application.

#### Scenario: Notes list
- **WHEN** a user views an application
- **THEN** all notes are displayed with author name, content, type, rating, and timestamp

### Requirement: Notes visible to all team members
The system SHALL make all notes visible to all users in the same tenant.

#### Scenario: Cross-user note visibility
- **WHEN** User A adds a note to an application
- **THEN** User B (same tenant) can see the note

### Requirement: Delete note
The system SHALL allow the note author to delete their own notes.

#### Scenario: Delete own note
- **WHEN** the note author deletes their note
- **THEN** the note is removed from the application

#### Scenario: Delete others' note
- **WHEN** a user tries to delete a note written by another user
- **THEN** the system prevents deletion with a permission error
