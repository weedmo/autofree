---
name: team-dispatch
description: Dispatch a feature implementation task to the Codex pane with goal package + sub-team API. Codex acts as implementer-supervisor and may spawn helpers. Use after /goal-set has produced goal.md.
argument-hint: "<feature-id>"
---

# /team-dispatch — Phase 6 of the team pipeline

Hand off implementation to Codex with a complete goal package.

## Steps

1. Confirm `<feature-id>` was provided. If not, ask which feature.

2. Verify the goal package is complete:
   - `.team/tasks/<feature-id>/goal.md` exists (run `/goal-set` if not)
   - `.team/tasks/<feature-id>/tools.md` exists
   - `.team/tasks/<feature-id>/plan.md` exists
   - Worktree `.worktree/<feature-id>/` exists (run `/team-split` if not)

3. Verify the tmux team session is running:
   ```bash
   tmux has-session -t "team-$(basename $(git rev-parse --show-toplevel 2>/dev/null || pwd))" 2>/dev/null
   ```
   If not, run `~/.claude/scripts/team.sh init` first (this attaches the user to tmux — warn them).

4. Dispatch:
   ```bash
   ~/.claude/scripts/pipeline.sh impl <feature-id>
   ```

5. Watch `.team/bus.log`:
   ```bash
   tail -f .team/bus.log
   ```
   Wait for one of:
   - `DONE <feature-id>` → success, report and recommend `/team-review <feature-id>`
   - `STUCK <feature-id> <reason>` → halt, surface the reason to the user, do **NOT** auto-recover

6. If neither marker appears within a reasonable wait, ask the user whether to keep waiting, attach to the codex pane to inspect, or abort.

## Failure policy

Per project rule: **failure → wait for human**. Never auto-retry or auto-escalate from this skill.
