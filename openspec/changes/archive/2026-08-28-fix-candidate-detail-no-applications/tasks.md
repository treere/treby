## 1. Guard profile handlers

- [x] 1.1 Guard `submit_request_info` in `candidates_live/show.ex` (line ~1175) against an empty applications list, returning a clear error flash
- [x] 1.2 Guard `submit_rejection` in `candidates_live/show.ex` (line ~1239) against an empty applications list, returning a clear error flash
- [x] 1.3 Confirm `send_new_message` remains nil-safe and works without an application reference

## 2. Verify

- [x] 2.1 Add a test: "Request Info" on a candidate with no applications shows an error and does not crash
- [x] 2.2 Add a test: "Reject" on a candidate with no applications shows an error and does not crash
- [x] 2.3 Add a test: "New Message" to a candidate with no applications succeeds
- [x] 2.4 Run `mix precommit` and fix any pending issues