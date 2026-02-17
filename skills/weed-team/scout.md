# Parallel Scout — Fast Context Gathering Before Dispatch

When the team is active and the user gives a task, run parallel scouts **before** planning.
This replaces the slow sequential file reading with simultaneous exploration.

## Trigger

Automatically when:
- Team is loaded/created AND
- User gives a work request (not a `/weed-team --` subcommand)

## Procedure

### Step 1: Read Project Index (instant, optional)

First resolve `$HOME` via Bash (`echo $HOME`), then:
```
Read: {HOME_DIR}/.claude/teams/weed-team-{project}/project-index.md
```
(Use absolute path, NOT `~`)

If exists → you already have project context. Scouts can be more targeted.
If not exists → scouts do broader exploration.

### Step 2: Spawn Parallel Scouts (2-3 Explore agents, haiku model)

Spawn ALL scouts simultaneously in a **single message with multiple Task calls**.
All scouts use **model: "haiku"** for speed and cost efficiency.

If Main has `project_context` (from CLAUDE.md parsing in Phase 0), inject it into each scout prompt.

```
Scout A — Structure Scout:
  Task:
    subagent_type: "Explore"
    model: "haiku"
    description: "Scout project structure"
    prompt: |
      ## Project Context
      {project_context if available — language, framework, key dirs}

      Project: {CWD}
      Task: "{user's task description}"

      Find all files and directories directly related to this task.
      Return: file paths + 1-line description of each.
      Max 20 files.
    run_in_background: true

Scout B — Code Scout:
  Task:
    subagent_type: "Explore"
    model: "haiku"
    description: "Scout related code"
    prompt: |
      ## Project Context
      {project_context if available — language, framework, key dirs}

      Project: {CWD}
      Task: "{user's task description}"

      Search for code related to this task using grep/glob.
      Keywords to search: {extract 3-5 keywords from task description}
      For each match, read the relevant function/class and summarize what it does.
      Return: file:line — summary (max 15 entries)
    run_in_background: true

Scout C — Test & Deps Scout (optional, spawn if task involves code changes):
  Task:
    subagent_type: "Explore"
    model: "haiku"
    description: "Scout tests and deps"
    prompt: |
      ## Project Context
      {project_context if available — language, framework, key dirs}

      Project: {CWD}
      Task: "{user's task description}"

      1. Find existing tests related to this task area
      2. Check what dependencies/imports the affected modules use
      3. Identify potential side effects of changes
      Return: test files + dependency chain summary
    run_in_background: true
```

### Step 3: Collect Results

Wait for all scouts to return (typically 3-5 seconds with haiku).
You now have:
- Which files are relevant
- What the code does
- What tests exist
- What dependencies are involved

### Step 4: Rough Plan + Dispatch

With scout results in hand, do a **fast rough plan** (not detailed):

1. Identify 2-4 subtasks from the scout results
2. Map each subtask to a team agent
3. On-demand spawn any agents not yet spawned (via spawn.md with project_context + task_context)
4. Each agent does its own detailed planning internally

```
For each subtask (parallel):
  SendMessage (if agent already spawned) or Task (if new spawn needed):
    Provide:
      - subtask description
      - relevant file list from scout results
      - scope boundaries
```

## Key Principles

- **Scouts are read-only** (Explore agents can't edit files) — they only gather info
- **Always spawn scouts in a single message** — they must run in parallel
- **All scouts use model: "haiku"** — fast (~3s) and cost-efficient (~67% cheaper than opus)
- **2 scouts minimum, 3 maximum** — more than 3 has diminishing returns
- **Skip Scout C** if the task is research/analysis only (no code changes)
- **Include scout file results in agent prompts** — agents skip their own exploration phase
- **Inject project_context** if available — scouts can be more targeted
