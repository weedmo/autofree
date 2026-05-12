---
description: "Spawn an isolated git worktree with a deterministic PORT_BASE so heavy multi-port dev servers can run in parallel across Claude sessions."
argument-hint: "<branch> [base-branch]  |  --list  |  --remove <branch> [--force]"
---

Run the worktree-spawn helper. Pass `$ARGUMENTS` straight through.

```bash
bash ~/.claude/scripts/worktree-spawn.sh $ARGUMENTS
```

After the script finishes:

- If a worktree was created, show the user the path and `PORT_BASE`, and remind them to run `direnv allow` inside the new worktree if they use direnv.
- If `--list` was used, show the table verbatim.
- If `--remove` was used, confirm the cleanup and note the released port.
- If the script errors (e.g., not inside a git repo, base branch missing), surface the error and suggest a fix.

Conventions this command assumes:

- Worktrees live at `../<repo>-worktrees/<branch>` (override with `WORKTREE_ROOT` env).
- Port allocations are tracked in `<repo>/.worktree-ports.json` — make sure it is gitignored.
- A committed `.envrc.template` in the repo defines the port layout (e.g. `API_PORT=$((PORT_BASE+1))`). The generated `.envrc` sources it.
