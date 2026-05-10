---
name: team-review
description: Review the Codex implementation result for a feature against goal.md exit criteria, apply small surgical refactors, then create a PR via /review + /ship. Use after /team-dispatch logs DONE.
argument-hint: "<feature-id>"
---

# /team-review — Phase 7 of the team pipeline

Final phase: verify Codex output, refactor if needed, ship a PR.

## Steps

1. Confirm `<feature-id>` was provided.

2. Verify the implementation is done:
   - `.team/tasks/<feature-id>/result.md` exists (Codex writes it on DONE)
   - `.worktree/<feature-id>/` exists
   - bus.log shows `DONE <feature-id>` (not `STUCK`)

3. cd into the worktree and gather diff context:
   ```bash
   cd .worktree/<feature-id>
   git diff main...HEAD     # adjust base branch as needed
   git log main..HEAD --oneline
   ```

4. Read `.team/tasks/<feature-id>/result.md` and `.team/tasks/<feature-id>/goal.md`.

5. Verify each Exit Criterion in goal.md against the actual diff. List PASS/FAIL per criterion.

6. If all PASS:
   - Apply only small surgical refactors needed for clarity (no scope creep).
   - Invoke `/review` skill for pre-landing review.
   - If `/review` passes, invoke `/ship` to create the PR. **Do NOT auto-merge.**
   - Report the PR URL.

7. If any FAIL:
   - List the failing criteria with concrete evidence (diff lines, missing files, broken tests).
   - Recommend one of:
     - Re-dispatch with refined goal: `/team-dispatch <feature-id>` after editing goal.md
     - Manual intervention in `.worktree/<feature-id>/`
   - Do **NOT** silently fix — surface the gap to the user.

## Failure policy

Per project rule: never amend Codex's commits silently. Either the work passes review or the user decides next steps.
