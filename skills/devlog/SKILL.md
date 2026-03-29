---
name: devlog
description: "개발 로그 허브 — devlog(개발 저널), tsg(트러블슈팅) 등 logs/ 하위 모든 로그를 통합 관리. /devlog로 기록, /devlog tsg로 트러블슈팅, /devlog search로 통합 검색."
---

# Devlog — 통합 개발 로그 허브

개발 작업의 기록을 `logs/` 하위 폴더별로 체계적으로 관리하는 단일 진입점.
- **devlog**: 개발 과정(시행착오, 접근법, 교훈) 기록
- **tsg**: 코드 이슈 해결 과정(증상, 원인, 해결) 기록

## Log Type Registry

| Type Key | Directory | ID Prefix | Description |
|----------|-----------|-----------|-------------|
| devlog | logs/devlog/ | DEVLOG | 개발 저널 (시행착오, 접근법, 교훈) |
| tsg | logs/troubleshooting/ | TSG | 트러블슈팅 가이드 (이슈 해결 기록) |

> 새 로그 타입 추가: 이 테이블에 행 추가 + Log Type Definition 섹션 추가 + 타입별 프로시저 추가

## Subcommands

| Command | Log Type | Action | User Confirmation |
|---------|----------|--------|-------------------|
| `/devlog` (no args) | devlog | 현재 대화에서 개발 과정 추출 → 문서 생성 | Required |
| `/devlog --auto` | devlog | Hook 자동 트리거 — 확인 없이 바로 작성 | **Skipped** |
| `/devlog --session <title>` | devlog | 세션 devlog 생성 (living doc) | Not needed |
| `/devlog --append <ID> <content>` | devlog | 기존 devlog에 내용 추가 | Not needed |
| `/devlog reject <ID>` | devlog | 사용자 거부 — user_validation → rejected | Required |
| `/devlog reject --auto <ID>` | devlog | Hook 자동 거부 (revert 커밋 감지) | **Skipped** |
| `/devlog search <keyword>` | **ALL** | 통합 검색 (전체 logs/) | Not needed |
| `/devlog list` | **ALL** | 통합 목록 (전체 logs/) | Not needed |
| `/devlog tsg` | tsg | 현재 대화에서 이슈 감지 → TSG 문서 생성 | Required |
| `/devlog tsg --auto` | tsg | Hook 자동 트리거 — 확인 없이 바로 작성 | **Skipped** |
| `/devlog tsg search <keyword>` | tsg | TSG 내 검색 | Not needed |
| `/devlog tsg list` | tsg | TSG 목록 | Not needed |
| `/devlog tsg unresolved` | tsg | 미해결 이슈 자동 기록 | Not needed (auto) |
| `/devlog tsg resolve <TSG-ID>` | tsg | 미해결 → 해결로 병합 | Required |

## Procedure

### Step 0: Detect Project Root and Logs Directory

```
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
LOGS_DIR="$PROJECT_ROOT/logs"
DEVLOG_DIR="$LOGS_DIR/devlog"
TSG_DIR="$LOGS_DIR/troubleshooting"
```

Create directories on-demand when first writing.

### Step 1: Parse Subcommand (Router)

```
args = user input after "/devlog"

1. If args[0] is a KNOWN_LOG_TYPE (tsg, ...):
     log_type = args[0]
     subcommand = args[1:]
     → Route to type-specific procedures (Step 3 for tsg)
2. Else:
     log_type = "devlog"
     subcommand = args[0:]
     → Route to devlog procedures (Step 2) or unified operations (Step 4/5)
```

Special routing:
- `search` (without type prefix) → **Unified Search** (Step 4)
- `list` (without type prefix) → **Unified List** (Step 5)
- `--auto`, `--session`, `--append`, `reject` → **Devlog Procedures** (Step 2)

---

## Step 2: Devlog Procedures

### Step 2A: Record Devlog (`/devlog`)

1. Analyze the current conversation to extract:
   - **목표**: 요청 사항, 작업의 목적
   - **접근 과정**: 각 시도별 결과와 원인 분석
   - **최종 해결**: 성공한 방법과 이유
   - **교훈**: 재사용 가능한 인사이트
   - **변경 파일**: 수정된 파일 목록
   - **task_type**: feature|bugfix|refactor|config|other
   - **complexity**: low|medium|high
   - **user_validation**: pending|accepted|rejected (default: pending)
   - **tags**: 검색용 키워드

2. Generate next **DEVLOG ID**:
   ```bash
   max_id=$(grep -h '^id: DEVLOG-' "$DEVLOG_DIR"/DEVLOG-*.md 2>/dev/null | sed 's/id: DEVLOG-0*//' | sort -n | tail -1)
   next_id=$(printf "DEVLOG-%03d" $((${max_id:-0} + 1)))
   ```

3. Generate a **slug** from the title (lowercase, hyphens, max 50 chars)

4. Estimate **duration** based on conversation length and complexity.

5. Show the draft to the user:

   ```
   ## Devlog Draft: {next_id}

   **Type**: {task_type}
   **Complexity**: {complexity}
   **Duration**: {duration_estimate}
   **Tags**: {tag1, tag2, ...}

   ### 목표 (Goal)
   - ...

   ### 접근 과정 (Approach Log)
   #### 1차 시도
   - **방법**: ...
   - **결과**: 실패|성공|부분성공
   - **원인**: ...

   #### 2차 시도
   - ...

   ### 최종 해결 (Final Solution)
   - ...

   ### 교훈 (Lessons Learned)
   - ...

   ### 변경 파일 (Changed Files)
   - `path/to/file.ts` — 변경 설명

   ---
   이 내용을 devlog로 기록할까요? (수정할 부분이 있으면 말씀해주세요)
   ```

6. **Wait for user confirmation** using AskUserQuestion. Do NOT write the file until confirmed.

7. On confirmation:
   - Create directory if needed: `mkdir -p "$DEVLOG_DIR"`
   - Write the devlog file with frontmatter (see Devlog File Format)
   - Update README.md index (Step 6)

### Step 2B: No Development Activity Detected

If no clear development activity is found in the conversation:
```
현재 대화에서 기록할 만한 개발 과정을 찾지 못했습니다.
특정 작업을 기록하고 싶다면 설명해주세요.
```

### Step 2C: Reject Devlog (`/devlog reject <ID>`)

1. Find the existing devlog file:
   ```bash
   find "$DEVLOG_DIR" -name "${DEVLOG_ID}*" -type f
   ```

2. If not found: `{DEVLOG_ID}를 찾을 수 없습니다. /devlog list로 확인해주세요.`

3. Read the existing file and verify `user_validation` is not already `rejected`.

4. Determine the rejection context:
   - **rejection_reason**: Why the user rejected
   - **reverted_commit**: The commit hash that was reverted (if applicable)
   - **metric_was_improved**: Whether the metric had improved before rejection (true/false)

5. If `--auto` flag is NOT set, show the rejection summary to the user:
   ```
   ## Devlog Reject: {DEVLOG_ID}

   **Original title**: {title}
   **Metric improved**: {yes/no}
   **Rejection reason**: {reason}
   **Reverted commit**: {commit_hash}

   ---
   이 devlog를 rejected로 업데이트할까요?
   ```

6. **Wait for user confirmation** using AskUserQuestion (skip if `--auto`).

7. On confirmation:
   - Update frontmatter: `user_validation: pending` → `user_validation: rejected`
   - Add `rejected_at: {date}` to frontmatter
   - Append a `## 거부 사유 (Rejection Reason)` section to the file body:
     ```markdown
     ## 거부 사유 (Rejection Reason)
     - **사유**: {rejection_reason}
     - **원복 커밋**: {reverted_commit}
     - **메트릭 개선 여부**: {yes/no}
     - **교훈**: {lesson from this rejection — what to avoid next time}
     ```
   - Update README.md index (Step 6) — Validation column reflects `rejected`
   - Display: `{DEVLOG_ID}를 rejected로 업데이트했습니다.`

### Step 2D: Create Session Devlog (`/devlog --session <title>`)

Session devlogs are living documents designed for long-running processes (autocode, auto_research, ralph loops).
Unlike regular devlogs, they are created at session start and continuously appended to.

1. Generate next DEVLOG ID (same as Step 2A).
2. Generate slug from title.
3. Create the devlog file with special frontmatter:

```markdown
---
id: DEVLOG-{NNN}
title: {title}
task_type: session
status: active
complexity: high
user_validation: pending
created: {date}
session_type: autocode|auto_research|ralph|custom
tags: [session, {extracted_tags}]
---

## {title}

Session started: {timestamp}

## Config
<!-- Populated by first --append call -->

## Progress
| # | Strategy | Change | Metric | Delta | Status |
|---|----------|--------|--------|-------|--------|

## Events
<!-- PIVOTs, REFINEs, mode changes logged here -->
```

4. Update README.md index (Step 6).
5. Return the DEVLOG ID for use by the calling skill.
6. **No user confirmation needed** — session devlogs are created programmatically.

### Step 2E: Append to Devlog (`/devlog --append <ID> <content>`)

Append content to an existing devlog entry. Used by autocode/auto_research to update session devlogs.

1. Find the devlog file by ID:
   ```bash
   find "$DEVLOG_DIR" -name "${DEVLOG_ID}*" -type f
   ```

2. If not found: error `{ID}를 찾을 수 없습니다.`

3. Parse the content to determine WHERE to append:
   - If content starts with `|` (table row): append to the `## Progress` table
   - If content starts with `###` (event header): append to the `## Events` section
   - If content starts with `## Config`: replace the Config section placeholder
   - If content starts with `## Final Summary`: append at the end of the file
   - Otherwise: append at the end of the file

4. Use `Edit` tool to insert content at the appropriate location.

5. Update the `status` frontmatter if content contains "Final Summary":
   - Change `status: active` → `status: completed`
   - Add `completed: {date}` to frontmatter

6. Update README.md index (Step 6) only on status change.

7. **No user confirmation needed** — append operations are programmatic.

---

## Step 3: TSG Procedures

### Step 3A: Record Resolved Issue (`/devlog tsg`)

1. Analyze the current conversation to extract:
   - **증상**: Error messages, observed behavior
   - **원인**: Root cause analysis
   - **해결**: Applied fix
   - **핵심 개념**: Technical concepts needed to understand
   - **재발 방지**: Prevention checklist
   - **tags**: Keywords for searchability
   - **test**: Test code tracking (if applicable):
     - `file`: Path to the test file that validates the fix
     - `command`: Command to run the test
     - `validation`: Result from `/test-validation` (pending / valid / bad_test / bad_fix / regression)
     - `fix_commit`: The commit hash that contains the fix

2. Determine **category** from the issue context (e.g., `build`, `api`, `database`, `config`, `auth`, `deploy`, `test`, `performance`, etc.)

3. Generate next **TSG ID**:
   ```bash
   max_id=$(grep -rh '^id: TSG-' "$TSG_DIR"/*/TSG-*.md 2>/dev/null | sed 's/id: TSG-0*//' | sort -n | tail -1)
   next_id=$(printf "TSG-%03d" $((${max_id:-0} + 1)))
   ```

4. Generate a **slug** from the title (lowercase, hyphens, max 50 chars)

5. Show the draft to the user:

   ```
   ## TSG Draft: {next_id}

   **Category**: {category}
   **Severity**: {low|medium|high|critical}
   **Tags**: {tag1, tag2, ...}

   ### 증상
   - ...

   ### 원인
   - ...

   ### 해결
   - ...

   ### 핵심 개념
   - ...

   ### 재발 방지
   - [ ] ...

   ---
   이 이슈를 TSG로 기록할까요? (수정할 부분이 있으면 말씀해주세요)
   ```

6. **Wait for user confirmation** using AskUserQuestion. Do NOT write the file until confirmed.

7. On confirmation:
   - Create category directory if needed: `mkdir -p "$TSG_DIR/{category}"`
   - Write the TSG file with frontmatter (see TSG File Format)
   - Update README.md index (Step 6)

**`--auto` flag behavior:** Skip steps 5-6 (showing draft and waiting for confirmation). Write immediately.

### Step 3B: No Issue Detected

If no clear issue/resolution is found in the conversation:
```
현재 대화에서 기록할 만한 이슈를 찾지 못했습니다.
특정 이슈를 기록하고 싶다면 설명해주세요.
```

### Step 3C: TSG Search (`/devlog tsg search <keyword>`)

1. Search across all TSG files in `$TSG_DIR`:
   ```bash
   grep -rl "<keyword>" "$TSG_DIR"/*/TSG-*.md 2>/dev/null
   ```

2. Also use Grep tool to search for the keyword in TSG file contents.

3. Display results as a table:
   ```
   ## TSG Search: "<keyword>"

   | ID | Status | Category | Title | Match Context |
   |----|--------|----------|-------|---------------|
   | TSG-001 | resolved | build | Webpack memory overflow | tags: [ENOMEM, heap] |
   ```

4. If no results: `"<keyword>"에 대한 TSG를 찾지 못했습니다.`

### Step 3D: TSG List (`/devlog tsg list`)

1. If `$TSG_DIR` does not exist:
   - Create `$TSG_DIR` and an empty `README.md`
   - Display: `TSG 디렉토리를 생성했습니다. 아직 등록된 TSG가 없습니다.`
   - Return

2. Read `README.md` and display the Quick Search table.

3. If no TSGs exist: `등록된 TSG가 없습니다.`

### Step 3E: Record Unresolved Issue (`/devlog tsg unresolved`)

1. Analyze conversation to extract:
   - **증상**: Error messages, observed behavior
   - **시도한 방법**: Approaches tried and their results
   - **현재 상태**: Current situation
   - **tags**: Keywords

2. Generate next TSG ID and slug (same as Step 3A).

3. **Write immediately without confirmation**:
   - Create category directory if needed
   - Write TSG file with `status: unresolved` (see TSG Unresolved Format)
   - Update README.md index (Step 6)

4. Create a project task for tracking:
   ```
   TaskCreate:
     description: "[TSG] {next_id}: {title} — 미해결 이슈 추적"
   ```

5. Display confirmation:
   ```
   미해결 이슈를 기록했습니다:
   - **{next_id}**: {title}
   - 파일: {relative_path}
   - 해결되면 `/devlog tsg resolve {next_id}`로 업데이트하세요.
   ```

### Step 3F: Resolve (`/devlog tsg resolve <TSG-ID>`)

1. Find the existing TSG file:
   ```bash
   find "$TSG_DIR" -name "${TSG_ID}*" -type f
   ```

2. If not found: `{TSG_ID}를 찾을 수 없습니다. /devlog tsg list로 확인해주세요.`

3. Read the existing file — preserve 증상 and 시도한 방법 sections.

4. Analyze current conversation to extract:
   - **원인**: Root cause (what was discovered)
   - **해결**: Applied fix
   - **핵심 개념**: Technical concepts
   - **재발 방지**: Prevention checklist

5. Show merged draft to user:
   ```
   ## TSG Resolve: {TSG-ID}

   ### 증상 (기존 보존)
   - ...

   ### 원인 (신규)
   - ...

   ### 해결 (신규)
   - ...

   ### 핵심 개념 (신규)
   - ...

   ### 재발 방지 (신규)
   - [ ] ...

   ---
   이 내용으로 {TSG-ID}를 해결 완료로 업데이트할까요?
   ```

6. **Wait for user confirmation** using AskUserQuestion.

7. On confirmation:
   - Update file: change `status: unresolved` → `status: resolved`, update `updated` date
   - Replace sections: remove 시도한 방법/현재 상태, add 원인/해결/핵심 개념/재발 방지
   - Update README.md index (Step 6)
   - Find and complete related task if exists

---

## Step 4: Unified Search (`/devlog search <keyword>`)

Search across ALL log types in `logs/`.

1. For each log type in the Registry:
   - Determine directory and file glob pattern
   - Search frontmatter tags, title, and body content using Grep tool

2. Merge results into a single table sorted by date descending:
   ```
   ## Log Search: "<keyword>"

   | Type | ID | Status | Title | Date | Match Context |
   |------|----|--------|-------|------|---------------|
   | TSG | TSG-001 | resolved | Webpack memory overflow | 2026-03-11 | tags: [ENOMEM] |
   | DEVLOG | DEVLOG-003 | completed | Refactor pipeline config | 2026-03-18 | body: "webpack config..." |
   ```

3. If no results: `"<keyword>"에 대한 로그를 찾지 못했습니다.`

---

## Step 5: Unified List (`/devlog list`)

Show a combined view of ALL log types.

1. For each log type in the Registry:
   - Read its directory's README.md index
   - Count entries

2. Display combined view:
   ```
   ## All Logs

   ### Devlog ({N} entries)
   | ID | Status | Validation | Type | Title | Date |
   |----|--------|------------|------|-------|------|
   ...

   ### TSG ({N} entries)
   | ID | Status | Severity | Category | Title | Date |
   |----|--------|----------|----------|-------|------|
   ...

   ### Recent Activity (top 10)
   | Date | Type | ID | Title |
   |------|------|----|-------|
   ...
   ```

3. If no logs exist across all types: `등록된 로그가 없습니다.`

---

## Step 6: Update Section README.md

After any log creation/modification, regenerate the section-specific index.

### For Devlog (`logs/devlog/README.md`)

1. Scan all `DEVLOG-*.md` files in `$DEVLOG_DIR`
2. Parse frontmatter from each file (id, status, task_type, complexity, title, tags, created)
3. Write `README.md`:

```markdown
# Devlog

## Index
| ID | Status | Validation | Type | Complexity | Title | Date | Keywords |
|----|--------|------------|------|------------|-------|------|----------|
| DEVLOG-001 | completed | accepted | feature | medium | Video timestamp correction | 2026-03-17 | video, timestamp |

## By Type
### feature
- [DEVLOG-001](DEVLOG-001-implement-video-timestamp.md) - Video timestamp correction

### bugfix
- [DEVLOG-002](DEVLOG-002-fix-auth-token-refresh.md) - Auth token refresh fix
```

### For TSG (`logs/troubleshooting/README.md`)

1. Scan all `TSG-*.md` files in `$TSG_DIR` subdirectories
2. Parse frontmatter from each file (id, status, severity, category, title, tags)
3. Write `README.md`:

```markdown
# Troubleshooting Guide

## Quick Search
| ID | Status | Severity | Category | Title | Keywords |
|----|--------|----------|----------|-------|----------|
| TSG-001 | ✅ resolved | high | build | Webpack memory overflow | ENOMEM, heap |
| TSG-002 | ❌ unresolved | medium | api | Stripe webhook timeout | webhook, 504 |

## By Category
### build/
- [TSG-001](build/TSG-001-webpack-memory-overflow.md) - Webpack memory overflow ✅

### api/
- [TSG-002](api/TSG-002-stripe-webhook-timeout.md) - Stripe webhook timeout ❌
```

---

## Step 7: Update Top-Level logs/README.md

After any log creation/modification, regenerate `$LOGS_DIR/README.md`:

```markdown
# Logs Index

> Auto-generated. Do not edit manually.

## Summary
| Section | Count | Path |
|---------|-------|------|
| Troubleshooting (TSG) | {N} | [troubleshooting/](troubleshooting/) |
| Devlog | {N} | [devlog/](devlog/) |
| PR Verify | {N} | pr-verify-*.md |

## Recent Activity
| Date | Type | ID | Title |
|------|------|----|-------|
| 2026-03-24 | TSG | TSG-003 | Prisma migration drift |
| 2026-03-23 | DEVLOG | DEVLOG-002 | Auth token refresh fix |

## Troubleshooting (TSG)
| ID | Status | Severity | Category | Title |
|----|--------|----------|----------|-------|

## Devlog
| ID | Type | Title | Date |
|----|------|-------|------|

## PR Verification Guides
| File | Branch |
|------|--------|
```

**Recent Activity**: Collect all TSG and DEVLOG files, sort by `updated` or `created` date descending, show top 10.

---

## Log Type Definitions

### Devlog File Format

```markdown
---
id: DEVLOG-001
title: Implement video timestamp correction
task_type: feature
status: completed
complexity: medium
user_validation: pending
created: 2026-03-17
duration_estimate: 3h
tags: [video, timestamp, ffmpeg]
---

## 목표 (Goal)
- 요청 사항과 작업 목적

## 접근 과정 (Approach Log)

### 1차 시도
- **방법**: 시도한 접근법
- **결과**: 실패
- **원인**: 실패 원인 분석

### 2차 시도
- **방법**: 수정된 접근법
- **결과**: 성공
- **원인**: 성공 이유

## 최종 해결 (Final Solution)
- 성공한 방법과 핵심 이유

## 교훈 (Lessons Learned)
- 재사용 가능한 인사이트

## 변경 파일 (Changed Files)
- `path/to/file.ts` — 변경 설명
```

### Session Devlog Format

Session devlogs have `task_type: session` and `status: active`.
They transition to `status: completed` when a `## Final Summary` is appended.
Session devlogs appear in `/devlog list` and `/devlog search` alongside regular devlogs.

### TSG Resolved Format

```markdown
---
id: TSG-001
title: Webpack 빌드 시 메모리 초과
status: resolved
category: build
severity: high
created: 2026-03-11
updated: 2026-03-11
tags: [webpack, memory, ENOMEM, heap]
related: []
---

## 증상
- 에러 메시지, 관찰된 동작

## 원인
- 근본 원인 분석

## 해결
- 적용한 수정 사항

## 핵심 개념
- 이해에 필요한 기술 개념

## 재발 방지
- [ ] 체크리스트 항목
```

### TSG Unresolved Format

```markdown
---
id: TSG-002
title: Stripe webhook 타임아웃
status: unresolved
category: api
severity: medium
created: 2026-03-11
updated: 2026-03-11
tags: [stripe, webhook, timeout, 504]
related: []
---

## 증상
- 에러 메시지, 관찰된 동작

## 시도한 방법
- 시도한 접근과 결과

## 현재 상태
- 현재 상황
```

---

## Key Principles

- **시행착오 과정이 핵심** — 최종 결과만이 아니라 중간 과정을 기록
- **사람이 읽기 좋은 문서가 먼저** — Claude는 참조만 한다
- **Progressive disclosure** — README.md 인덱스 → frontmatter 스캔 → body drill-down
- **반드시 사용자 확인 후 저장** — draft 보여준 뒤 확인받고 저장 (unresolved, session, append 제외)
- **ID는 재사용하지 않음** — 삭제해도 번호 건너뜀
- **README.md는 매 작업 후 자동 갱신** — 항상 최신 상태 유지
- **사용자 검증(user_validation)은 메트릭과 별개** — autocode 등에서 메트릭 개선이 되어도 사용자가 방향을 거부하면 rejected로 기록
- **Session devlogs are living documents** — created once, appended many times, closed once
- **Append is idempotent-safe** — duplicate content detection prevents double-writes
- **단일 진입점** — `/devlog`가 모든 로그 타입의 라우터. 새 타입은 Registry에 추가만 하면 됨
- **통합 검색/목록** — 타입 없이 호출하면 전체 logs/ 횡단, 타입 지정하면 해당만
