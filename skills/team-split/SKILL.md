---
name: team-split
description: Split a master plan (from /grill-me) into per-feature git worktrees + task directories with PRD/plan/goal/tools templates. Use when the master plan is ready to fan out into parallel feature work.
---

# /team-split — Phase 2 of the team pipeline

Split the master plan into independent feature workstreams.

## Steps

1. Verify `.team/plan/master.md` exists. If not, tell the user to run `/grill-me` first to produce it.
2. Confirm the master plan has `## feat-<id>` headings (one per feature). If none found, ask the user to add them.
3. Run:
   ```bash
   ~/.claude/scripts/pipeline.sh split
   ```
4. Report what was created: list each `.worktree/feat-*` and `.team/tasks/feat-*/` directory.
5. Recommend the next phase: `/to-prd` per feature, then `/refine-plan <feature-id>`.

## Notes

- Re-running `team-split` is idempotent: existing task dirs and worktrees are preserved.
- If the working directory is not a git repo, worktree creation is skipped (task dirs still made).
- Templates copied: `prd.md`, `plan.md`, `goal.md`, `tools.md` — all under `.team/tasks/<feature-id>/`.
