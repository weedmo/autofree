# On-Demand Spawn Procedure

Shared procedure for spawning agents. Called by create.md (core), team-dispatch.md (on-demand), add.md, and update.md.

## Inputs

- `team_name`: 활성 팀 이름
- `agents_to_spawn`: spawn할 에이전트 이름 리스트
- `project_context`: (선택) Main이 CLAUDE.md에서 추출한 구조화된 정보
- `task_context`: (선택) 서브태스크 설명 + scout 파일 목록

## 1. Model Lookup

`agent-reference.md` 테이블에서 각 에이전트의 Model 컬럼 조회.
Task tool의 `model` 파라미터 값: `"opus"`, `"sonnet"`, `"haiku"`

**Model 기본값:**
- agent-reference에 없는 이름 → `"sonnet"`
- Scout (Explore) → `"haiku"`

## 2. Context-Rich Prompt 생성

### Case A: project_context + task_context 둘 다 있을 때 (on-demand spawn)

```
You are {agent_name} on team {team_name}.

## Project Context
- Language: {language}
- Framework: {framework}
- Dependencies: {key dependencies}
- Conventions: {coding conventions}
- Constraints: {constraints}

Do NOT read CLAUDE.md — all project context is above.

## Your Task
{subtask description}

## Relevant Files (from scout)
{file list with summaries}

## Scope
{boundaries — what to touch, what NOT to touch}

Plan your approach, then execute. Report back when done.
```

### Case B: project_context만 있을 때 (update/add)

```
You are {agent_name} on team {team_name}.

## Project Context
- Language: {language}
- Framework: {framework}
- Dependencies: {key dependencies}
- Conventions: {coding conventions}

Do NOT read CLAUDE.md — all project context is above.

Check TaskList for any tasks assigned to you and execute them.
If no tasks are assigned, stand by. Respond when the team leader sends you a message.
```

### Case C: 둘 다 없을 때 (코어 에이전트 초기 spawn)

```
You are {agent_name}, a core member of team {team_name}.
Await task assignment via SendMessage from the team leader.
Check TaskList periodically for tasks assigned to you.
```

## 3. Spawn (병렬)

Spawn ALL agents simultaneously in a **single message with multiple Task calls**:

```
For each agent in agents_to_spawn (ALL in parallel):
  Task:
    subagent_type: "{agent_name}"
    name: "{agent_name}"
    team_name: "{team_name}"
    model: "{model}"          ← agent-reference에서 조회한 값
    description: "Spawn {agent_name}"
    prompt: "{context_rich_prompt}"
    run_in_background: true
```

## subagent_type Mapping

Agent name and subagent_type are **identical** for all 27 agents:

| Agent Name | subagent_type |
|-----------|---------------|
| debugger | debugger |
| test-engineer | test-engineer |
| code-reviewer | code-reviewer |
| document-structure-analyzer | document-structure-analyzer |
| python-pro | python-pro |
| rust-pro | rust-pro |
| cpp-pro | cpp-pro |
| c-pro | c-pro |
| shell-scripting-pro | shell-scripting-pro |
| ml-engineer | ml-engineer |
| mlops-engineer | mlops-engineer |
| data-engineer | data-engineer |
| data-scientist | data-scientist |
| sql-pro | sql-pro |
| database-architect | database-architect |
| database-admin | database-admin |
| database-optimizer | database-optimizer |
| database-optimization | database-optimization |
| supabase-schema-architect | supabase-schema-architect |
| nosql-specialist | nosql-specialist |
| deployment-engineer | deployment-engineer |
| devops-troubleshooter | devops-troubleshooter |
| network-engineer | network-engineer |
| mcp-expert | mcp-expert |
| prompt-engineer | prompt-engineer |
| error-detective | error-detective |
| unused-code-cleaner | unused-code-cleaner |
