# Workspace Switching

One email and password for all your companies. Each company is a separate workspace with its own jobs, candidates, and settings — you can be Admin in one and Member in another.

![Choose workspace](/screenshots/27-workspace-picker.png)

*Choose workspace — after login, anyone with multiple companies sees the list with their role. Below, **Create new company**.*

![Header workspace switcher](/screenshots/28-header-switcher.png)

*Header menu (visible with more than one workspace) — shows the current company with a checkmark and role, plus **Create new company**.*

## Where to Find It

* **At login** — after email and password, if you belong to multiple companies you see **Choose workspace**. Pick a company to continue.
* **In the header** — when you have more than one workspace, next to the Treby logo there's a menu with the current company name. Open it to switch instantly.
* **Create new company** — in the picker or header menu, choose **Create new company**, enter a name, and become Admin of the new workspace.

## How to Use It

1. **Sign in** with email and password.
   * One workspace → go directly to `your-company/app`.
   * Multiple workspaces → land on **Choose workspace** with the list of companies and your role (Admin / Member).

2. **Pick a workspace** — click a company. The whole app loads in that context: jobs, candidates, pipeline, and analytics are scoped to that company.

3. **Switch on the fly** — open the company menu in the header and select another company. The URL becomes `other-company/app` and the app reloads. Bookmarks keep the workspace (`company/app/jobs/123`).

4. **Create another company** — from the picker or the menu, **Create new company** → enter a name → you are redirected to the new workspace as Admin. No new password needed: the same one works everywhere.

5. **Compatibility** — old bookmarks like `/app/jobs` still work and take you to your first workspace or the picker if you have more than one.

## Roles per Workspace

The role is **per company**, not global.

| You are | In that company you can |
|---|---|
| **Admin** | Manage **Settings → Pipeline**, **Team**, **Fields**, **Sources**, branding, invitations |
| **Member** | Use jobs, candidates, applications, notes, interviews, and scorecards according to stage permissions |

You only see workspaces you have been invited to.

## Invitations

* **Admin → Settings → Team → Invite** — invite by email to the current workspace. The invitee receives a link.
* **If the email already exists** — Treby does not create a duplicate: it adds the person to the workspace with the password they already use.
  * Not signed in → you see **Sign in as name@email to accept the invitation**.
  * Already signed in with the same email → **Join Company Name** (one click, no new registration).
  * Signed in with a different email → **You are signed in as other@company.com but the invitation is for name@email — Sign out and continue as name@email**.

Invitations expire after 7 days.

## Tips

* The workspace switcher is hidden if you have only one workspace.
* The company slug in the URL comes from the name (e.g., `acme-corp`) and does not change after creation.
* **Reset password** is global: the new password works for all your workspaces.
