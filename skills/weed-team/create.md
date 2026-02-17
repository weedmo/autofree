# Mode A: Team Creation

**IMPORTANT: No confirmation step.** TeamCreate → Spawn core 4 → Display. Fast and lightweight.

## Step 1: TeamCreate

1. Determine project name:
   - If `CLAUDE.md` exists in CWD → extract `project_name`
   - If no CLAUDE.md → use CWD directory name
2. If task description was provided after `/weed-team`, store as `task_description`

```
TeamCreate:
  team_name: "weed-team-{sanitized_project_name}"
  description: "{project_name} - weed-team"
```

Team name: `weed-team-{sanitized_project_name}` (spaces/special chars → `-`, lowercase).
Example: "Tommoro Dataset Manager" → `weed-team-tommoro-dataset-manager`

## Step 2: Spawn Core Agents

Read `spawn.md` and spawn the **4 core agents only**, with no project_context and no task_context (Case C prompt):

| Agent | Model |
|-------|-------|
| debugger | sonnet |
| test-engineer | sonnet |
| code-reviewer | opus |
| document-structure-analyzer | sonnet |

These are spawned in **parallel, in background**. Do NOT wait for them to finish.

## Step 3: Output

```markdown
## Weed-Team Created

**Team:** `weed-team-{name}`
**Core agents:** 4 (spawning in background)

| # | Agent | Model | Status |
|---|-------|-------|--------|
| 1 | debugger | sonnet | spawning |
| 2 | test-engineer | sonnet | spawning |
| 3 | code-reviewer | opus | spawning |
| 4 | document-structure-analyzer | sonnet | spawning |

### How it works
Task를 주면:
1. CLAUDE.md 읽고 필요한 에이전트 결정 (tier algorithm)
2. 병렬 scouts로 코드 파악 (haiku, ~3s)
3. 필요한 에이전트만 올바른 model로 on-demand spawn
4. 각 에이전트에 프로젝트 컨텍스트 + 태스크 컨텍스트 주입

### Commands
- Check status: `/weed-team --status`
- Update team: `/weed-team --update`
- Add agent: `/weed-team --add <name>`
- Disband: `/weed-team --disband`
```

**Removed from old flow:** CLAUDE.md parsing, tier-algorithm, Doc output prompt, project-index generation, --load reference.
All of these now happen **on first task dispatch** (see team-dispatch.md Phase 0).
