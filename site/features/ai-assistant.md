# AI Assistant

A built-in assistant for your hiring team. Ask it what a page does, have it manage your jobs, or get suggestions for the text you are writing — all without leaving the page you are working on.

![AI Assistant chat](/screenshots/44-ai-assistant.png)

## Where to find it

The assistant is available on every page inside a workspace, for signed-in team members. Candidates never see it.

- **Floating widget** — click the assistant button in the bottom-right corner of any page to open it, and close it when you are done. The panel floats over the page, so you can keep scrolling and working underneath.
- **Full page** — open **Assistant** in the top navigation, or go to **`/<workspace>/app/ai`**, for a full-width chat.

You can **drag the widget by its header** to move it anywhere on the screen, and **drag the bottom-right corner** to make it larger or smaller. It always stays inside the visible window.

The widget remembers whether it was open and where you placed it: leave it open, move or resize it, change page or refresh, and it comes back the same way. This is remembered per browser.

## What it can do

The assistant acts **as you**: it can read and change exactly what your role allows in the current workspace, and nothing more. What it offers therefore depends on your role — **admin**, **recruiter**, or **interviewer** (see **Settings → Team → Roles & permissions**):

- **Recruiting** — list and open jobs, candidates and applications; search candidates; create candidates and applications; move applications between pipeline stages; mark applications reviewed; add, edit and delete notes; schedule, reschedule, complete and cancel interviews; submit scorecards; compare candidates; read pipelines and stage assignments.
- **Analytics** — pipeline statistics, conversion and hiring-funnel reports, job-view counts, candidate comparisons, and a workspace dashboard summary.
- **Communications** — send or schedule messages to candidates, list, reschedule, cancel or retry scheduled messages, and read email templates.
- **Workspace admin** *(admins only)* — add, remove or change the role of team members; invite people; configure pipelines and stages and who is assigned to them; manage custom fields and the career page; import candidates from CSV; run bulk actions; manage notifications, data-privacy requests and webhooks; and read the audit log.

The assistant also keeps the general abilities:

- **Answer questions about the platform** — it knows which page you are on, including the filters and data on it, and explains what to do there.
- **Read the form and the page you are working on** — when a page has a form it can see the fields, and it can also read the main record on the page (a job, candidate, application, or stage) to give accurate answers.
- **Propose form text fixes** — when you are editing a form, it can suggest corrected or pre-filled values. Confirm the suggestion and the values are applied to the form on the page for you.
- **Switch specialist** — if your request spans more than one area, ask the assistant to switch and it hands the conversation to the relevant specialist.

Admins see the full set of tools. Recruiters and interviewers never see or run denied actions, even if they ask: those requests are refused, and the corresponding menus and buttons are hidden too.


## Chatting

1. Open the widget or the **Assistant** page.
2. Type your message and press **Send**.
3. The reply appears as it is written, formatted as rich text — headings, lists, code, and tables render as you watch.
4. The chat scrolls automatically to the newest message. If you have scrolled up to read earlier messages, it only scrolls once you go back to the bottom.
5. Keep using the page while the reply is being written; the assistant works in the background.

## Your conversation

- The conversation is saved **per user and per workspace**, so it is private to you.
- Changing page or refreshing the browser keeps the same conversation.
- Logging in starts a **new conversation**. Previous conversations are kept in storage but are no longer shown; no messages are ever deleted.
- Multiple tabs of the same login stay in sync: a reply that completes in one tab appears in the others.

## Confirming actions

Anything that writes stays pending until you approve it.

1. The assistant proposes the action and shows a **confirmation card**.
2. Review the details on the card.
3. Click **Confirm** to apply it, or **Cancel** to discard.
4. Nothing is changed, and nothing is recorded in the audit log, until you confirm.

Each proposed action is confirmed on its own — there is no "accept all".

## Resetting the conversation

Click **Reset** at the top right of the chat and confirm. This starts a fresh conversation. The previous one is kept in storage but is no longer shown; no messages are deleted.

## Limits

- Messages are rate-limited per user to keep usage predictable.
- The assistant works on the current workspace only, and only within your role. It never reads or changes another workspace, and nobody can trigger actions their role denies.
- Every action it performs on your behalf is written to the **Audit Log** (admin only, under **Settings → Audit Log**) so you can always see what happened and who approved it.
