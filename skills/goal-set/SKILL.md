---
name: goal-set
description: Compress an APPROVE'd plan.md into goal.md (testable exit criteria + constraints + sub-team tools) for Codex to execute. Run after /refine-plan locks the plan.
argument-hint: "<feature-id>"
---

# /goal-set — Phase 5 of the team pipeline

Derive a Codex-executable `goal.md` from a hardened `plan.md`.

## Steps

1. Confirm `<feature-id>` was provided. If not, ask which feature.
2. Verify `.team/tasks/<feature-id>/plan.md` exists.
3. Check `.team/tasks/<feature-id>/.refine-verdict.json` — if `final` is not `APPROVE`, warn the user and recommend running `/refine-plan <feature-id>` first. Ask whether to proceed anyway.
4. Run:
   ```bash
   ~/.claude/scripts/pipeline.sh goal <feature-id>
   ```
5. Read the generated `goal.md` and report:
   - The Goal sentence
   - Count of Exit Criteria
   - Count of Constraints
6. Recommend next: `/team-dispatch <feature-id>`.

## Why a separate goal.md

`plan.md` is for humans (decisions, alternatives, ADR). `goal.md` is for Codex — only what's needed to execute. Keeping them separate prevents Codex from wasting cycles on design rationale and keeps the goal verifiable.
