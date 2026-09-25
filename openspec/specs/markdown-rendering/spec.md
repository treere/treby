# Markdown Rendering

## Purpose

Provide one consistent, sanitized Markdown-to-HTML pipeline for all user- and
assistant-authored content in Treby (job descriptions, company branding, job
previews, assistant replies), including GFM table support.

## Requirements

### Requirement: Shared Markdown rendering

The system SHALL render all user- and assistant-authored Markdown through a
single shared renderer (CommonMark plus the GFM table extension) followed by a
strict sanitizer allowlist. The same renderer SHALL serve job descriptions,
company branding, job previews, and assistant replies.

#### Scenario: Tables render as HTML

- **WHEN** Markdown input contains a GFM table (header row, separator row, body rows)
- **THEN** the output contains a `<table>` with `<thead>`/`<th>` cells and `<tbody>`/`<td>` cells

#### Scenario: Tables render in every surface

- **WHEN** a Markdown table appears in a job description, company about text, or an assistant reply
- **THEN** it is rendered as an HTML table in all of those surfaces

#### Scenario: Wide table stays readable

- **WHEN** a rendered table is wider than its container
- **THEN** the table scrolls horizontally within the container instead of breaking the layout

### Requirement: Sanitized table markup

The system SHALL allow only `table`, `thead`, `tbody`, `tr`, `th`, and `td` tags
with no attributes, and SHALL continue to strip scripts, raw HTML, images, and
dangerous URLs from rendered Markdown.

#### Scenario: Table allowed without attributes

- **WHEN** a Markdown table is rendered
- **THEN** the resulting table tags carry no `style`, `class`, or event-handler attributes

#### Scenario: Dangerous content still stripped

- **WHEN** Markdown input contains a table together with a `<script>` tag or a `javascript:` link
- **THEN** the table is rendered while the script and the dangerous URL are removed
