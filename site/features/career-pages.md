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

Clicking a job shows the full description and a meta row with salary, location, employment type (Full-time/Part-time/Contract/Internship), workplace (On-site/Hybrid/Remote), and posted date, plus an **Apply Now** button. If you already applied while logged into the portal, the button becomes **Already applied — View status**.

Job cards in the listings also show location and type badges, and an **Applied ✓** badge appears on positions you've already applied to when you're logged into the portal.

## Application Form

![Application Form](/screenshots/18-apply-form.png)

External candidates can apply through a clean form with:

- Full name, email, phone number
- Resume upload (PDF, DOC, DOCX — max 10MB) with **visible feedback**: after picking a file you see the filename and size, a progress bar while uploading, a green check when done, and a **Remove** button; errors like *"File type not accepted"* or *"File too large"* appear inline in red next to the field
- The **Submit** button is disabled and shows *Uploading…* with a spinner until the upload finishes; if you picked a file but it has errors, submitting keeps the form open and shows *"Please fix the resume upload or remove the file to apply without a CV"* — you are never left wondering if your CV arrived
- A **Need help?** block appears under the form (and again on the thank-you screen) with your company's contact email when configured in the tenant settings — the email is shown only if present
- Custom application fields (if configured)
- Location and contract details shown on the job (configured in **Jobs**)

If you're logged into the candidate portal for that company, the form is **prefilled** with your name/email/phone and shows a hint — you can still edit before submitting. Submitting again to the same position shows **You have already applied on …** instead of creating a duplicate.

Applications are automatically placed in the first pipeline stage. Candidates are deduplicated by email.

After a successful submit you see **Thank you!** with clear next steps: *"Check your email — including spam — for a 10-minute code to track your application"* and a primary **Track your application** button linking to the portal login.

## Portal-Enabled Applications

When the candidate portal is active, the application flow gains additional features:

- **Welcome conversation**: A conversation is automatically created when a candidate submits their application
- **Portal link in confirmation ping**: The confirmation email links to the candidate portal
- **OTP login**: Candidates can return anytime using just their email and a one-time login code — no account setup required

## Branding

Configure your career page look in **Settings → Branding**:

- **Page Title** — heading displayed on the careers page
- **Description** — company description
- **Primary Color** — accent color (color picker)
- **Logo** — upload PNG/JPG/SVG (max 5MB)
- **Published** — toggle visibility

A live preview panel shows how the page header will look with your current settings.
