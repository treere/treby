# Data & Privacy — Data Export & Erasure

Treby helps you honor data-subject requests (access, portability, erasure) with an async, auditable workflow.

## Where to find it

- **Company requests:** `Settings → Data & Privacy` (admin only) — list, create, and monitor all requests for the workspace.
- **Your own data:** `Settings → Data & Privacy` shows `Export my data` and `Delete my account` for any member; admins also see `Export company data` and `Delete company`.

## What it does

- **Export** — builds a ZIP with `export.json` (users, candidates, applications, notes, interviews, scorecards, messages) plus original resume files. The package is generated in the background and is available for **7 days**.
- **Erasure** — anonymizes personal data (not hard-delete, so pipelines and audit keep their shape). A **7-day grace period** lets you cancel before anything is scrubbed. Company erasure requires typing the company slug to confirm.
- **Download** — uses a **signed URL** (valid 1 hour) that points directly to S3 — the file is never proxied through the app, and the key is tenant-scoped.
- **Audit** — every transition (`requested`, `ready`, `downloaded`, `completed`, `cancelled`, `expired`) is logged in `Settings → Audit Log` under `data_privacy.*`.

## How to use

### Request an export

1. Go to `Settings → Data & Privacy`.
2. Click **Export my data** (own data) or **Export company data** (admin, full workspace).
3. The request appears as `pending → processing → ready`.
4. When `ready`, click **Download** — you get a 302 to a signed URL (1h). If expired, the button disappears and the row shows `expired`.

### Request an erasure

1. Go to `Settings → Data & Privacy`.
2. Click **Delete my account** (self) or **Delete company** (admin — type the company slug).
3. The request stays `pending` for 7 days — use **Cancel** to undo.
4. After grace, the system anonymizes candidates (`Deleted Candidate …`, `deleted+id@deleted.local`), nulls phones/links, clears custom fields, deletes resumes from storage, and scrubs audit metadata.

### Tips

- Tenant exports include all candidates/jobs/applications/notes — member exports only include your own notes/scorecards/interviews.
- You cannot erase the last admin — transfer ownership first.
- Expired exports are purged automatically; download links never leak raw S3 keys in HTML.
