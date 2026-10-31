# REPLAN_NOTES

## Objective
Provide the planner with clear input to revise the plan when execution reveals blockers, gaps, or better paths.

## When to write
- A step fails or becomes risky.
- New evidence changes the expected path.
- The plan is incomplete, outdated, or inefficient.

## Required fields
- Request rewrite: short, faithful restatement of the user request.
- Current context: what was being executed.
- Blocker or signal: what triggered replanning.
- Evidence: logs, outputs, files, tests, or links.
- Attempts made: what was tried and what happened.
- Impact: what cannot proceed and why.
- Recommendation: objective suggestion for the next plan revision.

## Rules
- Be concise, factual, and actionable.
- Prefer bullets.
- Do not rewrite the full plan here.
- Update existing notes instead of duplicating the same issue.
