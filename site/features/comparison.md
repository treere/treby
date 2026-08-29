# Candidate Comparison

Side-by-side evaluation of 2–3 candidates.

## How to use

From the candidates list (`/app/candidates`) select 2–3 candidates and choose **Compare** (or navigate directly to `/app/candidates/compare` with `?ids=`).

Implemented in `lib/treby/comparison/comparison.ex` and `lib/treby_web/live/comparison_live/index.ex`.

## What is compared

`Comparison.compare_candidates/1` loads for each candidate:

- contact info (name, email, phone, LinkedIn)
- all applications with job + stage
- notes with star ratings and authors
- interview scorecards (where present)

The UI renders a table-like comparison with one column per candidate so you can scan strengths/deficiencies without flipping between profiles.

## Limits

- Minimum 2, maximum 3 candidates — otherwise `{:error, "Select 2-3 candidates to compare"}`.
- Only candidates within your tenant are visible; missing IDs simply return fewer columns.
