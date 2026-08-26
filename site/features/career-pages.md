# Public Career Pages

Each tenant can publish a branded career page for external applicants—no account needed.

![Public Careers Page](/screenshots/16-public-careers.png)

## How it works

Career pages are live at `/:tenant_slug/careers` and show:

- Company title and description
- All open job postings with salary ranges
- Styled with the tenant's brand color

## Job Detail Page

![Public Job Detail](/screenshots/17-public-job-detail.png)

Clicking a job shows the full description, salary range, and an **Apply Now** button.

## Application Form

![Application Form](/screenshots/18-apply-form.png)

External candidates can apply through a clean form with:

- Full name, email, phone number
- Resume upload (PDF, DOC, DOCX — max 10MB)
- Custom application fields (if configured)

Applications are automatically placed in the first pipeline stage. Duplicate candidates are deduplicated by email.

## Portal-Enabled Applications

When the candidate portal is active, the application flow gains additional features:

- **Welcome conversation**: A conversation is automatically created when a candidate submits their application
- **Portal link in confirmation email**: The thank-you email includes a link to the candidate portal
- **Magic link login**: Candidates can return anytime using just their email — no account setup required

## Branding

Configure your career page look in **Settings → Branding**:

- **Page Title** — heading displayed on the careers page
- **Description** — company description
- **Primary Color** — accent color (color picker)
- **Logo** — upload PNG/JPG/SVG (max 5MB)
- **Published** — toggle visibility

A live preview panel shows how the page header will look with your current settings.
