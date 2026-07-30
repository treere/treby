## ADDED Requirements

### Requirement: Landing page communicates product value
The site SHALL display a landing page that communicates Treby's value proposition, key features, and a call-to-action within the first viewport.

#### Scenario: Visitor sees hero section
- **WHEN** a visitor navigates to the site root
- **THEN** they see a hero section with project name, tagline, and a Get Started link

#### Scenario: Visitor sees feature highlights
- **WHEN** scrolling below the hero
- **THEN** they see 3-5 key feature cards with icons and brief descriptions

### Requirement: Feature documentation pages exist per major feature
The site SHALL have dedicated pages for each major Treby feature, each with a description and screenshots.

#### Scenario: Feature page navigation
- **WHEN** a visitor clicks a feature link in the sidebar
- **THEN** they see a page with feature description, screenshots, and usage details

#### Scenario: Pipeline feature page
- **WHEN** a visitor navigates to the pipeline feature page
- **THEN** they see the Kanban board screenshot, drag-and-drop description, and real-time update explanation

#### Scenario: Career pages feature page
- **WHEN** a visitor navigates to the career pages feature page
- **THEN** they see public career page screenshots, branding customization description, and application flow explanation

### Requirement: Full-text search across all site content
The site SHALL provide built-in full-text search that indexes all documentation pages.

#### Scenario: Search returns results
- **WHEN** a visitor types a query in the search box
- **THEN** they see relevant results from across the site with page titles and content snippets

#### Scenario: Search works offline
- **WHEN** a visitor searches without network connectivity
- **THEN** search STILL returns results (Vitepress search index is pre-built)

### Requirement: Getting-started guide
The site SHALL have a getting-started page that explains prerequisites, setup, and seed data.

#### Scenario: Setup instructions are visible
- **WHEN** a visitor navigates to the getting-started page
- **THEN** they see prerequisite requirements, setup commands, and demo credentials

### Requirement: Architecture overview page
The site SHALL have an architecture page explaining the tech stack and system design.

#### Scenario: Architecture content is visible
- **WHEN** a visitor navigates to the architecture page
- **THEN** they see the tech stack table, architecture diagram (ASCII), and design decisions

### Requirement: Responsive and professional design
The site SHALL have a responsive layout that works on desktop and mobile, with consistent styling.

#### Scenario: Mobile layout
- **WHEN** a visitor views the site on a screen narrower than 768px
- **THEN** the sidebar collapses into a hamburger menu, and content reflows to single-column

#### Scenario: Consistent styling
- **WHEN** a visitor navigates between any pages
- **THEN** typography, colors, spacing, and component styling are consistent

### Requirement: Screenshots are embedded on feature pages
Feature documentation pages SHALL embed screenshots that illustrate the feature.

#### Scenario: Screenshot visible on feature page
- **WHEN** a visitor opens a feature page
- **THEN** they see relevant screenshots with captions describing what is shown
