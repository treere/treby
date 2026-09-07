# career-page (delta)

## Modified Requirements

### Requirement: Public career page content
The company description shown at the top of the public career page is
authored as plain Markdown in Settings → Brand and rendered as sanitized
HTML (headings, lists, links, emphasis). The textarea carries a short hint
that Markdown is supported.

#### Scenario: Markdown company description
- **WHEN** a company description contains Markdown (e.g. a list or a link)
- **THEN** the career page top shows it rendered (list bullets, clickable link)
- **AND** any raw HTML/script content is stripped
