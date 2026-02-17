# /weed-team - Lazy Spawn Agent Team from CLAUDE.md

Creates a lightweight core team instantly. Additional agents spawn **on-demand** when tasks require them,
with the correct model (opus/sonnet/haiku) from agent-reference.md.

## Usage

| Command | Description |
|---------|-------------|
| `/weed-team [task description]` | **Create** core team (4 agents, instant) |
| `/weed-team --update` | Re-parse CLAUDE.md and add new agents |
| `/weed-team --status` | Show current team members + status |
| `/weed-team --add <agent-name>` | Manually add an agent |
| `/weed-team --disband` | Disband the entire team |

**Team naming:** `weed-team-{sanitized_project_name}` (auto-derived from CLAUDE.md or CWD)
**Config auto-saved by TeamCreate at:** `~/.claude/teams/weed-team-{project}/config.json`

## Architecture

```
/weed-team → TeamCreate → Core 4 spawn (sonnet/opus) → Ready (~5s)
Task given → Main reads CLAUDE.md → tier algorithm → scouts (haiku) → on-demand spawn → dispatch
```

**Core agents** (always spawned on creation):
- debugger (sonnet), test-engineer (sonnet), code-reviewer (opus), document-structure-analyzer (sonnet)

**On-demand agents** (spawned when task requires them):
- 23 additional specialists from agent-reference.md
- Each spawned with correct model (opus for 4 specialists, sonnet for rest)
- Project context injected in prompt — agents do NOT read CLAUDE.md

**Scouts** (ephemeral, haiku model):
- 2-3 Explore agents for fast parallel code exploration before dispatch

## Path Resolution (GLOBAL RULE — applies to ALL modes)

**CRITICAL:** The `~` tilde does NOT expand in tool parameters (Glob, Read, Write, etc.).
Before ANY file operation on `~/.claude/`, you MUST first resolve the home directory:

```
Bash: echo $HOME
```

Then use the absolute path (e.g., `/home/weed/.claude/teams/...`) in all tool calls.
**Never** pass `~` to Glob `path`, Read `file_path`, or Write `file_path` parameters.

**Glob quirk:** Single-level `*` patterns like `weed-team-*/config.json` DO NOT WORK in `.claude/teams/`.
Always use `**` recursive prefix: `**/weed-team-*/config.json`.

## Routing

Parse the argument after `/weed-team`:
- Starts with `--` → subcommand (read the corresponding mode file only)
- Anything else (text or empty) → team creation (Mode A)

**Read ONLY the corresponding file(s).** Do NOT read other mode files.

| Argument | File to Read |
|----------|-------------|
| No `--` flag (text or empty) | `create.md` → `spawn.md` |
| `--update` | `update.md` → `tier-algorithm.md` → `agent-reference.md` → `spawn.md` |
| `--status` | `status.md` |
| `--add <name>` | `add.md` → `agent-reference.md` → `spawn.md` |
| `--disband` | `disband.md` |

All mode files are in: `~/.claude/skills/weed-team/`

**If a team already exists in the current session when create is invoked:**
```
Team `weed-team-{project}` is already active.
- Check status: `/weed-team --status`
- Update: `/weed-team --update`
- To recreate, first run `/weed-team --disband`.
```

## Task Dispatch Workflow

When the team is active and the user gives a work request (not a `/weed-team --` command),
the **team-dispatch.md** orchestrator handles:

```
1. Phase 0: Read CLAUDE.md + tier algorithm → select additional agents
2. Phase 2: Spawn 2-3 haiku scouts in parallel → ~3-5s, task-specific files
3. Phase 6: On-demand spawn needed agents → dispatch with context
```

Agents receive project context + task context in their spawn prompt,
so they do NOT need to read CLAUDE.md themselves. This saves ~92% tokens vs old full-spawn approach.

## External Skill Integration (weed-team 활성 시)

**weed-team이 활성 상태일 때, 코드 수정을 포함하는 외부 skill도 에이전트에 위임한다.**

### 코드 수정 포함 skill (team dispatch 경유)

다음 skill들은 코드를 수정하므로, weed-team 활성 시 **Main이 직접 수정하지 않고 적합한 에이전트에 위임**:

| Skill | 위임 대상 | 이유 |
|-------|----------|------|
| `/sc:cleanup` | Agent Selection Matrix로 도메인별 전문가 | 코드 수정 포함 |
| `/sc:implement` | Agent Selection Matrix로 도메인별 전문가 | 기능 구현 |
| `/sc:improve` | code-reviewer + 도메인 전문가 | 코드 개선 |
| `/sc:troubleshoot` | debugger + 도메인 전문가 | 버그 수정 |
| `/sc:git` | 해당 없음 (Main 직접 처리 가능) | git 명령만 |

### 위임 흐름

```
1. 외부 skill 실행 (예: /sc:cleanup @db/indexed.py)
2. Main이 대상 파일/키워드 분석
3. team-dispatch.md의 Agent Selection Matrix 참조
   → db/ 키워드 → sql-pro 선별
   → cleanup 키워드 → code-reviewer 선별
4. Scout(haiku)로 관련 코드 파악
5. 선별된 에이전트(sql-pro)에 수정 작업 dispatch
6. code-reviewer가 결과 리뷰
7. Main은 최종 검증만 수행
```

### 분석 전용 skill (Main 직접 처리 가능)

| Skill | Main 직접 | 이유 |
|-------|----------|------|
| `/sc:analyze` | O | 읽기 전용 분석 |
| `/sc:explain` | O | 설명만 |
| `/sc:estimate` | O | 추정치만 |
| `/sc:research` | O | 탐색만 |

## Important Notes

- **No confirmation step on create.** Core team is auto-created immediately
- **On-demand spawn:** Additional agents only when tasks need them
- **Model separation:** opus (4 specialists) / sonnet (23 agents) / haiku (scouts)
- **Context injection:** Agents get project info in prompt, not from CLAUDE.md
- **Main은 코드를 직접 수정하지 않는다** — 항상 적합한 에이전트에 위임
- **Agent Selection Matrix:** 태스크 키워드/파일 경로 → 도메인 → 최적 에이전트 자동 매핑
- To assign work to an agent, use SendMessage with the agent's `name`
- Duplicate agents are automatically deduplicated
