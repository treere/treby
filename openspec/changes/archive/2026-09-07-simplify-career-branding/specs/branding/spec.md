# branding (delta)

## Modified Requirements

### Requirement: Career page branding
The Brand settings form contains only title, subtitle (short description),
about (long Markdown story), and save — no logo upload, no color picker,
no Published toggle. Branding is always live. An Edit/Preview tab switcher
shows the rendered result (title, subtitle, about) exactly as the public
page displays it.

#### Scenario: Edit company story
- **WHEN** an admin writes Markdown in the about field
- **THEN** the Preview tab shows it rendered (headings, lists, links)
- **AND** saving publishes it immediately with no extra step

## REMOVED Requirements

### Requirement: Set logo / Set primary color scenarios
**Reason**: Logo upload and color picker removed from the form as unused.
**Migration**: `logo_url`/`primary_color` columns retained, UI only.
