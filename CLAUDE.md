# weed-harness - Global Rules

## Parallel Execution

Always run **independent tasks in parallel**. Never serialize work that has no dependencies.

| Parallel OK | Must be Sequential |
|-------------|-------------------|
| Editing different files/modules | Edit A → test A |
| Code analysis + doc analysis | Analysis → implementation plan |
| Independent module refactors | DB schema change → ORM update |

## Git Commits

Do NOT include `Co-Authored-By` lines in commit messages.

## Scout Before Complex Tasks

For non-trivial tasks, use `/scout` to gather context before planning or implementation.
This launches parallel Explore agents that map out relevant files, code, tests, and dependencies.
