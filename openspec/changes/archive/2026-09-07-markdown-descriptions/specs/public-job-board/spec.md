# public-job-board (delta)

## Modified Requirements

### Requirement: Public job detail content
The job description on the public job detail page is rendered as sanitized
HTML from its Markdown source (replacing the plaintext block). The company
block keeps showing name, logo, and description, with the description
rendered from Markdown as well.

#### Scenario: Markdown job description
- **WHEN** a job description contains Markdown (e.g. headings or a list)
- **THEN** the public detail page shows it rendered
- **AND** any raw HTML/script content is stripped
