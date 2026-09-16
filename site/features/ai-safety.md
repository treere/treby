# AI Safety

The assistant is built to stay helpful and safe: it answers only about your hiring workspace, and it reviews every reply before you see it.

## What it means in practice

- **Stays on-topic** — if you ask something outside the workspace (a recipe, general trivia, or anything unrelated to hiring), it politely says it can only help with the workspace and does not act on the request.
- **Blocks harmful requests** — attempts to trick it (prompt injection), to ignore its instructions, or to reach another workspace's data are refused, and the attempt is logged.
- **Reviews its own replies** — before a reply is saved and shown, it is checked for appropriateness and formatting, and for any sign of leaked data (another workspace's records, secrets, or out-of-scope personal data). If something is off, the reply is cleaned up or blocked.
- **Never leaves the workspace** — it always operates on the workspace you are signed in to and cannot read or change another company's data.

## Where this applies

These safeguards protect every conversation in the assistant — both the floating widget and the **Assistant** page. They sit on top of the per-action confirmation for anything that writes data, so two layers keep you in control:

1. The request is checked before the assistant does anything.
2. Any action that changes data waits for your explicit confirmation.
3. The final reply is reviewed before it is shown.

## Notes for administrators

- Refusals of harmful requests are written to the **Audit Log** (**Settings → Audit Log**) so administrators can see attempts.
- The safety review is a best-effort check, not a guarantee. The real boundary is workspace-scoped data plus your confirmation on every write.
- Debug tracing for the assistant is off by default and only enabled by a configuration flag, so normal use stays quiet.
