# AI Assistant

A built-in assistant for your hiring team. Ask it what a page does, have it manage your jobs, or get suggestions for the text you are writing — all without leaving Treby.

![AI Assistant chat](/screenshots/44-ai-assistant.png)

## Where to find it

Open **Assistant** in the top navigation, or go to **`/<workspace>/app/ai`**. It is available only inside a workspace, for signed-in team members. Candidates never see it.

## What it can do

- **Answer questions about the platform** — it knows which page you are on and explains what to do there.
- **List your jobs** — read-only, shown straight away.
- **Create, update, or delete a job** — these change data, so each one requires your confirmation first.
- **Propose form text fixes** — when a form is in context, it can suggest corrected or pre-filled values. Suggestions are advisory: you apply them yourself.

## Chatting

1. Open the **Assistant** page.
2. Type your message and press **Send**.
3. The assistant replies once the answer is ready (no partial typing animation).
4. Your conversation is saved per user and per workspace — leave the page and come back, and it is still there.

Multiple tabs of the same workspace and user stay in sync: a reply that completes in one tab appears in the others.

## Confirming actions

Anything that writes stays pending until you approve it.

1. The assistant proposes the action and shows a **confirmation card**.
2. Review the details on the card.
3. Click **Confirm** to apply it, or **Cancel** to discard.
4. Nothing is changed, and nothing is recorded in the audit log, until you confirm.

Each proposed action is confirmed on its own — there is no "accept all".

## Resetting the conversation

Click **Reset** at the top right and confirm. This starts a fresh conversation. The previous one is kept in storage but is no longer shown; no messages are deleted.

## Limits

- Messages are rate-limited per user to keep usage predictable.
- The assistant works on the current workspace only. It never reads or changes another workspace.
- Every action it performs on your behalf is written to the **Audit Log** (admin only, under **Settings → Audit Log**) so you can always see what happened and who approved it.
