---
name: scout
description: "Fast parallel reconnaissance using lightweight Explore agents before implementation. Use /scout when starting a new task to quickly gather project context — file structure, related code, tests, and dependencies — in parallel before planning or coding."
---

# Scout — Parallel Reconnaissance

Spawn 2-3 lightweight Explore agents in parallel to gather context before planning or implementation.
Scouts are **read-only** — they gather information, they never edit files.

## When to Use

- Before implementing a new feature or fix
- Before planning a complex refactor
- When entering an unfamiliar codebase or module

## Procedure

### Step 1: Determine Scout Count

| Task complexity | Scouts |
|----------------|--------|
| Simple (1-2 files) | 1 scout or direct Read |
| Medium (1 module) | 2 scouts in parallel |
| Complex (multi-module) | 3 scouts in parallel |

### Step 2: Spawn Scouts in a Single Message

All scouts must be launched **simultaneously** in one message with multiple Agent calls.

```
Scout A — Structure Scout:
  Agent:
    subagent_type: "Explore"
    description: "Scout project structure"
    prompt: |
      Project: {CWD}
      Task: "{user's task description}"

      Find all files and directories directly related to this task.
      Return: file paths + 1-line description of each.
      Max 20 files.
    run_in_background: true

Scout B — Code Scout:
  Agent:
    subagent_type: "Explore"
    description: "Scout related code"
    prompt: |
      Project: {CWD}
      Task: "{user's task description}"

      Search for code related to this task using grep/glob.
      Keywords to search: {extract 3-5 keywords from task}
      For each match, read the relevant function/class and summarize.
      Return: file:line — summary (max 15 entries)
    run_in_background: true

Scout C — Test & Deps Scout (optional, only if task involves code changes):
  Agent:
    subagent_type: "Explore"
    description: "Scout tests and deps"
    prompt: |
      Project: {CWD}
      Task: "{user's task description}"

      1. Find existing tests related to this task area
      2. Check what dependencies/imports the affected modules use
      3. Identify potential side effects of changes
      Return: test files + dependency chain summary
    run_in_background: true
```

### Step 3: Collect & Synthesize

Wait for all scouts to return. You now have:
- Which files are relevant
- What the code does
- What tests exist
- What dependencies are involved

### Step 4: Plan or Dispatch

With scout results, proceed to planning or direct implementation:
1. Identify subtasks from scout results
2. Map each subtask to the appropriate approach
3. Include relevant file lists from scout results in any agent prompts

## Key Principles

- **Scouts are read-only** — Explore agents cannot edit files
- **Always spawn in a single message** — they must run in parallel
- **2 scouts minimum, 3 maximum** — more has diminishing returns
- **Skip Scout C** for research/analysis tasks (no code changes)
- **Pass scout results downstream** — agents skip redundant exploration
