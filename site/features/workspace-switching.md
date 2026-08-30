# Workspace Switching

Use one email and password across several companies. Each company is a separate workspace with its own jobs, candidates, and settings — your role can be different in each.

## Where to find it

* **At login** — after entering email and password you see **Choose workspace** if you belong to more than one company. Pick one to continue.
* **In the app header** — when you have more than one workspace, a dropdown next to the Treby logo shows the current company. Open it to switch.
* **Create new company** — inside the picker or the header dropdown choose **Create new company**, enter a name, and you become admin of the new workspace at `your-company/app`.

## How to use

1. **Log in** with email and password.
   * One workspace → you go straight to `your-company/app`.
   * Several workspaces → you land on **Choose workspace** with each company and your role (Admin/Member).
2. **Pick a workspace** — you are taken to `company/app` where all data is scoped to that company (jobs, candidates, pipeline).
3. **Switch while working** — open the header dropdown, select another company. The URL changes to `other-company/app` and the whole app reloads in that context. Bookmarks keep their workspace (`company/app/jobs/123`).
4. **Create another business** — from the switcher or the picker, **Create new company** → name it → you are redirected to the new workspace as admin. No new password is needed; one password works everywhere.
5. **Backwards compatibility** — old bookmarks like `/app/jobs` still work and land in your first workspace or the picker if you have several.

## Permissions

* Role is **per workspace**. You can be **Admin** in your own company and **Member** in another — settings and team management are only available where you are Admin.
* You only see workspaces you have been invited to.

## Invites

* **Admin → Settings → Team → Invite** sends an invite for the current workspace.
* If the email already belongs to an existing Treby user, the invite adds them to the new workspace instead of creating a duplicate — they keep their existing password.

## Tips

* The header switcher is hidden when you only have one workspace.
* Company URLs are based on the company name (slug, e.g. `acme-corp`). The slug does not change after creation.
* Password reset is global — changing it updates your password for all workspaces.
