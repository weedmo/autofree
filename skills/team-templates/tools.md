# Sub-team API (for implementer-supervisor)

You are the **implementer-supervisor** for this feature. Beyond writing code, you may spawn helpers and consult researchers via the team.sh CLI.

## Commands

### Spawn a helper sub-agent (async, new tmux pane)
```
team.sh sub <name> <agent> "<prompt>"
```
Opens a new tmux pane running `<agent>` with the given prompt. Use for parallel work that can run while you continue.

Examples:
- `team.sh sub typecheck codex "run tsc --noEmit and report errors"`
- `team.sh sub lint codex "run eslint --fix and report remaining issues"`
- `team.sh sub doc-fetch gemini "summarize Stripe webhook signature verification"`

### Ask a researcher (synchronous, returns markdown)
```
team.sh ask gemini "<query>"
```
Use for documentation, library lookups, best practices.

Examples:
- `team.sh ask gemini "PKCE OAuth2 best practices 2026"`
- `team.sh ask gemini "Anthropic prompt caching: when to use cache_control"`

### Log to bus (audit trail)
```
team.sh log "<message>"
```

## Required Lifecycle Markers

Before exiting, run **exactly one** of:
- `team.sh log "DONE <feature-id>"` — work complete, `result.md` written
- `team.sh log "STUCK <feature-id> <reason>"` — blocked; halt and wait for human

## Constraints

- Do **NOT** modify files outside the worktree at `.worktree/<feature-id>/`
- Do **NOT** run destructive git ops (push --force, reset --hard) unless `goal.md` explicitly approves
- Do **NOT** auto-merge or push to main; that is reserved for the review phase
- Write final summary + diff highlights to `.team/tasks/<feature-id>/result.md` before logging `DONE`
- If sub-agent or ask call fails 3 times consecutively, log `STUCK` and halt
