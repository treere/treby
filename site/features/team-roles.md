# Team Roles & Permissions

Invite people with the right level of access: admins run the workspace, recruiters do the daily hiring work, and interviewers focus on interviews and scorecards. Admins can fine-tune what each role is allowed to do.

## Where to find it

Open **Settings → Team** (admins only). The page has three parts:

- **Team Members** — everyone in the workspace with name, email, and role.
- **Roles & permissions** — the matrix described below.
- **Pending Invites** — invitations that have not been accepted yet.

## The three roles

| Role | Typical use | Default access |
|------|-------------|----------------|
| Admin | Workspace owners | Everything. Cannot be restricted. |
| Recruiter | Hiring managers, sourcers | Jobs, candidates, applications, notes, interviews, messages, analytics, availability. |
| Interviewer | Engineers and hiring-team helpers | View jobs and candidates, see interviews, submit scorecards, manage own availability. |

Blocked by default for non-admins (an admin can grant them per workspace): deleting jobs or candidates, merging candidates, managing pipelines and stage assignments, inviting people, changing settings, managing custom fields, webhooks, imports, data-privacy exports, and the audit log.

People who had the old "member" role automatically become recruiters with the same access as before.

## How to invite someone

1. Go to **Settings → Team** and click **Invite Member**.
2. Enter their email and pick **Admin**, **Recruiter**, or **Interviewer**.
3. Send the invite. They receive an email with a link valid for 7 days.
4. To remove someone, click **Remove** next to their name. Their notes stay visible, marked as a former member.

## How to change what a role can do

1. Go to **Settings → Team → Roles & permissions**.
2. Find the action (for example *Manage pipelines* or *Delete candidates*).
3. Flip the switch for **Recruiter** or **Interviewer**. Admin-only items show an *Admin only* badge and cannot be changed.
4. The change applies immediately: menus, buttons, and pages the role lost disappear, and the assistant stops offering those actions too. Every change is recorded in the audit log.

Example: let recruiters manage the pipeline without becoming admins — turn on *Manage pipelines* for **Recruiter**. They will see **Settings → Pipeline Stages**; interviewers still will not.

## What people see

- Team members only see the settings, buttons, and pages their role allows. There are no dead links: denied items are hidden, not disabled.
- Trying to open a denied page directly (for example via a bookmark) returns to the dashboard with a notice.
- The assistant acts strictly within the same permissions: it never shows or runs actions the current role is denied, even when asked.
- Moving a candidate between stages additionally requires being assigned to that stage (or managing pipelines), on top of the role permission.
