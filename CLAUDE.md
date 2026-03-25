# weed-harness - Global Rules

## Parallel Execution

Always run **independent tasks in parallel**. Never serialize work that has no dependencies.

| Parallel OK | Must be Sequential |
|-------------|-------------------|
| Editing different files/modules | Edit A → test A |
| Code analysis + doc analysis | Analysis → implementation plan |
| Independent module refactors | DB schema change → ORM update |

## Branch Workflow (Mandatory)

When starting development work in a git repo connected to GitHub:
1. **MUST** check the current branch with `git branch` and `git remote -v`
2. **MUST** ask the user before writing any code:
   - Which branch to base the work on (e.g., `main`, `develop`, existing feature branch)
   - What to name the new branch (or whether to work on the current branch)
3. **Do NOT** proceed with any code changes until the user confirms the branch setup
4. Create and checkout the branch only after user confirmation

## Git Commits

Do NOT include `Co-Authored-By` lines in commit messages.

## Scout Before Complex Tasks

For non-trivial tasks, use `/scout` to gather context before planning or implementation.
This launches parallel Explore agents that map out relevant files, code, tests, and dependencies.
