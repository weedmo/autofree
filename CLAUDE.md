# Global Rules

## Weed-Team Active Mode

weed-team이 활성 상태(팀 에이전트가 spawn된 상태)일 때 다음 규칙을 **반드시** 따른다:

### Main은 코드를 직접 수정하지 않는다

- Edit, Write 도구로 소스코드(.py, .rs, .ts, .js, .cpp, .c, .sh 등)를 **직접 수정 금지**
- 모든 코드 수정은 적합한 에이전트에 **SendMessage 또는 Task로 위임**
- Main의 역할: 분석 → 에이전트 선별 → dispatch → 검증 **만**

### Agent Selection (파일/키워드 → 에이전트 매핑)

| 키워드/경로 | 에이전트 |
|------------|---------|
| db/, sql, schema, migration, duckdb | sql-pro |
| error, bug, fix, crash, traceback | debugger (코어) |
| test, coverage, pytest, assert | test-engineer (코어) |
| review, cleanup, refactor, dead code | code-reviewer (코어) |
| .py, python, async | python-pro |
| ml, model, train, inference | ml-engineer |
| docker, deploy, ci, k8s | deployment-engineer |
| doc, readme, structure | document-structure-analyzer (코어) |

코어 에이전트(debugger, test-engineer, code-reviewer, document-structure-analyzer)는 이미 spawned → SendMessage로 즉시 dispatch.
비코어 에이전트는 on-demand spawn (agent-reference.md 참조, model: opus/sonnet).

### 외부 Skill 통합

`/sc:cleanup`, `/sc:implement`, `/sc:improve`, `/sc:troubleshoot` 등 코드 수정 포함 skill 실행 시에도 위 규칙 적용:
1. 대상 파일/키워드 분석
2. Agent Selection으로 적합한 에이전트 선별
3. Scout(haiku)로 코드 파악
4. 에이전트에 수정 작업 dispatch
5. Main은 결과 검증만

### 예외 (Main 직접 처리 가능)

- git 명령어 (commit, push 등)
- 읽기 전용 분석 (`/sc:analyze`, `/sc:explain`)
- CLAUDE.md, README.md 등 문서 파일 수정
- weed-team 비활성 상태에서의 모든 작업
