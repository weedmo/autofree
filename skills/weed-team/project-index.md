# Project Index Generation

Generate a cached project summary during team creation or first dispatch.
This eliminates file exploration on subsequent task dispatches.

## When to Generate

- On first task dispatch (if not yet cached)
- Manually via `/weed-team --update` (regenerate)

## Generation Procedure

Spawn a **single Explore agent** in background using **haiku model**:

```
Task:
  subagent_type: "Explore"
  model: "haiku"
  description: "Build project index"
  prompt: |
    Analyze the project at {CWD} and produce a structured summary.
    Read CLAUDE.md first if it exists, then explore the codebase.

    Output the following sections in markdown:

    ## Directory Structure
    (key directories only, max 3 levels deep, skip node_modules/venv/.git/build)

    ## Modules
    | Module/Dir | Purpose | Key Files |
    (one row per major directory)

    ## Entry Points
    - Main: {path}
    - Tests: {path}
    - Config: {path}

    ## Dependency Graph (simplified)
    - {module A} → {module B} (brief reason)

    ## Test Structure
    | Test Dir | Framework | Approx Coverage |

    ## Key Patterns
    - Architecture: {monolith/modular/microservice/etc.}
    - State management: {if applicable}
    - API style: {REST/GraphQL/gRPC/etc.}

    Be concise. Each section max 15 lines.
  run_in_background: true
```

## Save Location

After the Explore agent returns, save the result to:
```
{HOME_DIR}/.claude/teams/weed-team-{project}/project-index.md
```
(Resolve `$HOME` first — never use `~` in tool parameters)

## Usage

When dispatching work later, read this one file instead of re-exploring the entire project.
If the file doesn't exist, skip it — scouts will gather context instead.
