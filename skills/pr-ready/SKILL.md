---
name: pr-ready
description: "PR 준비 워크플로우: 테스트 전체 통과 → logs/에 검토자용 테스트 실행 가이드 작성 → 가이드대로 재실행하여 검증 → PR 생성. /pr-ready로 PR 날리기 전에 사용. gh pr create를 직접 쓰려 할 때도 이 skill을 먼저 실행할 것."
---

# PR Ready Workflow

PR을 생성하기 전에 테스트 통과, 검토자용 가이드 작성, 가이드 검증을 자동으로 수행한다.

## Steps

### Step 1: 프로젝트 감지

변경된 파일로부터 프로젝트 유형을 파악한다.

```bash
# 변경된 파일 목록
git diff --name-only main...HEAD
```

- `pyproject.toml` 존재 → Python 프로젝트 (`pytest -v`)
- `package.json` 존재 → Node 프로젝트 (`npm test` / `npm run build`)
- 여러 서브프로젝트가 변경된 경우 각각 독립적으로 처리

변경된 파일이 속한 디렉토리에서 가장 가까운 `pyproject.toml` 또는 `package.json`을 기준으로 프로젝트 루트를 결정한다.

### Step 2: 테스트 실행 및 통과

해당 프로젝트의 전체 테스트를 실행한다.

- Python: `cd <PROJECT_DIR> && pytest -v`
- Node: `cd <PROJECT_DIR> && npm test`

**실패 시:**
1. 실패 원인 분석 → 코드 수정
2. 테스트 재실행
3. **3회 시도 후에도 실패하면 STOP** — 사용자에게 실패 내용 보고

**모든 테스트가 green이 될 때까지 다음 단계로 진행하지 않는다.**

### Step 3: 검토자용 문서 작성

`<PROJECT_DIR>/logs/pr-verify-<branch-name>.md` 파일을 생성한다.

브랜치 이름은 `git branch --show-current`로 가져온다. 슬래시(`/`)는 하이픈(`-`)으로 치환한다.

**템플릿:**

```markdown
# PR Verification Guide: <branch-name>

## What Changed
- (1-3줄 변경 요약)

## Prerequisites
```bash
# 환경 설정 명령어 (venv 활성화, npm install 등)
```

## How to Run Tests
```bash
# copy-paste 가능한 명령어 (절대경로 사용)
cd /absolute/path/to/project
pytest -v  # 또는 npm test
```

## Expected Output
```
(실제 통과한 테스트 출력 붙여넣기)
```
```

**제약:**
- 40줄 이내
- 설명 최소화, 실행 가능성 최우선
- 모든 경로는 절대경로

### Step 4: 문서 검증 (핵심)

작성한 문서를 처음 보는 검토자 입장으로 검증한다.

1. 문서를 처음부터 읽는다
2. **문서에 적힌 모든 명령어를 그대로 실행한다**
3. 실제 출력과 Expected Output 섹션을 비교한다
4. 불일치 시 문서 수정 → 처음부터 재검증

**2회 재시도 후에도 불일치하면 STOP** — 사용자에게 보고한다.

### Step 5: Update Top-Level logs/README.md

PR verify 문서 작성 후, `$PROJECT_ROOT/logs/README.md` 상위 인덱스도 갱신한다.
TSG 스킬의 Step 8에 정의된 포맷을 따라 전체 섹션(troubleshooting, devlog, pr-verify)을 스캔하여 재생성.

### Step 6: PR 생성

모든 검증이 통과하면 PR을 생성한다.

```bash
# 문서 파일 커밋
git add <PROJECT_DIR>/logs/pr-verify-*.md
git commit -m "docs: add PR verification guide for <branch-name>"

# PR 생성
gh pr create --title "<PR 제목>" --body "$(cat <<'EOF'
## Summary
<변경 요약>

## Verification Guide
📄 `<PROJECT_DIR>/logs/pr-verify-<branch-name>.md`

### Quick Verify
```bash
<문서에 적힌 테스트 실행 명령어>
```

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

사용자에게 PR URL을 보고한다.
