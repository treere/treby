## Context

`create/2` pattern-matched `%{"email" => email}`, so a request without the key crashed, and `search: ""` means "no filter" in the candidates query, so a blank email matched the first candidate.

## Goals / Non-Goals

- Goal: never send a code for a blank email and never 500 on malformed input.
- Non-goal: change the anti-enumeration message for unknown (but non-blank) emails.

## Decisions

- `create/2` matches only `tenant_slug` and derives the email with `to_string/1` + trim + downcase; blank short-circuits to a redirect with an error flash.
- `verify/2` trims the session/params email and applies the same blank guard before the rate limit.
- `request_link.ex` renders the `:error` flash.

## Risks / Trade-offs

- A blank email is now a distinct visible error rather than a silent success; this does not reveal whether any account exists.
