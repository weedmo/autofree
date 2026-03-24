---
name: devlog
description: "개발 저널 — 개발 과정(시행착오, 접근법, 교훈)을 체계적으로 기록/검색/관리. /devlog로 기록, /devlog search로 검색, /devlog list로 목록 조회."
---

# Devlog — 개발 저널

개발 작업 수행 후 "어떤 목표였고, 어떤 시행착오를 거쳤고, 어떻게 해결했는지"를 기록하여:
- **사람**: 개발 과정을 회고하고 학습
- **Claude**: 다음 세션에서 같은 실수를 반복하지 않도록 참조

핵심 원칙: **시행착오 과정이 핵심** — 최종 결과물뿐 아니라 중간 과정을 남긴다.

## Subcommands

| Command | Action | User Confirmation |
|---------|--------|-------------------|
| `/devlog` (no args) | 현재 대화에서 개발 과정 추출 → 문서 생성 | Required |
| `/devlog --auto` | Hook에 의해 자동 트리거 — 확인 없이 바로 작성 | **Skipped** |
| `/devlog reject <ID>` | 사용자 거부 — user_validation을 rejected로 변경, 거부 사유 기록 | Required |
| `/devlog reject --auto <ID>` | Hook에 의해 자동 트리거 (revert 커밋 감지) — 확인 없이 처리 | **Skipped** |
| `/devlog search <keyword>` | 기존 devlog 검색 (frontmatter tags + title + 본문) | Not needed |
| `/devlog list` | 전체 목록 조회 (README 테이블) | Not needed |

## Directory Structure

Devlog files are stored per-project under `logs/devlog/` (flat, no subdirs):

```
<project-root>/logs/devlog/
├── README.md                                  ← Index (auto-generated/updated)
├── DEVLOG-001-implement-video-timestamp.md
├── DEVLOG-002-fix-auth-token-refresh.md
└── DEVLOG-003-refactor-pipeline-config.md
```

## Procedure

### Step 0: Detect Project Root and Devlog Directory

```
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
DEVLOG_DIR="$PROJECT_ROOT/logs/devlog"
```

If `$DEVLOG_DIR` does not exist, create it along with `README.md` when first writing a devlog.

### Step 1: Parse Subcommand

Parse the user's input to determine which subcommand to execute:
- No args → **Record workflow** (Step 2A or 2B)
- `--auto` → **Auto-record workflow** (Step 2A, skip confirmation in Step 5-6)
- `reject <ID>` → **Reject workflow** (Step 2C)
- `reject --auto <ID>` → **Auto-reject workflow** (Step 2C, skip confirmation)
- `search <keyword>` → **Search workflow** (Step 3)
- `list` → **List workflow** (Step 4)

**`--auto` flag behavior:** Follow Step 2A identically, but skip Step 5 (showing draft) and Step 6 (waiting for confirmation). Write the devlog file directly. This flag is used by PostToolUse hooks when code work completes.

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
   # Find max existing ID
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
   - Write the devlog file with frontmatter (see format below)
   - Update `README.md` index (Step 5)

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
   - **rejection_reason**: Why the user rejected (e.g., "wrong direction", "approach doesn't align with architecture goals")
   - **reverted_commit**: The commit hash that was reverted (if applicable)
   - **metric_was_improved**: Whether the metric had improved before rejection (true/false, for autocode context)

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
   - Update `README.md` index (Step 5) — Validation column reflects `rejected`
   - Display: `{DEVLOG_ID}를 rejected로 업데이트했습니다.`

### Step 3: Search (`/devlog search <keyword>`)

1. Search across all devlog files in `$DEVLOG_DIR`:
   ```bash
   grep -rl "<keyword>" "$DEVLOG_DIR"/DEVLOG-*.md 2>/dev/null
   ```

2. Also use Grep tool to search for the keyword in devlog file contents.

3. Display results as a table:
   ```
   ## Devlog Search: "<keyword>"

   | ID | Type | Status | Title | Match Context |
   |----|------|--------|-------|---------------|
   | DEVLOG-001 | feature | completed | Video timestamp correction | tags: [video, timestamp] |
   ```

4. If no results: `"<keyword>"에 대한 devlog를 찾지 못했습니다.`

### Step 4: List (`/devlog list`)

1. If `$DEVLOG_DIR` does not exist:
   - Create `$DEVLOG_DIR` and an empty `README.md`
   - Display: `Devlog 디렉토리를 생성했습니다. 아직 등록된 devlog가 없습니다.`
   - Return

2. Read `README.md` and display the index table.

3. If no devlogs exist: `등록된 devlog가 없습니다.`

### Step 5: Update README.md Index

After any devlog creation, regenerate the index:

1. Scan all `DEVLOG-*.md` files in `$DEVLOG_DIR`
2. Parse frontmatter from each file (id, status, task_type, complexity, title, tags, created)
3. Write `README.md` with this structure:

```markdown
# Devlog

## Index
| ID | Status | Validation | Type | Complexity | Title | Date | Keywords |
|----|--------|------------|------|------------|-------|------|----------|
| DEVLOG-001 | completed | accepted | feature | medium | Video timestamp correction | 2026-03-17 | video, timestamp |
| DEVLOG-002 | completed | rejected | bugfix | low | Auth token refresh fix | 2026-03-17 | auth, token |

## By Type
### feature
- [DEVLOG-001](DEVLOG-001-implement-video-timestamp.md) - Video timestamp correction

### bugfix
- [DEVLOG-002](DEVLOG-002-fix-auth-token-refresh.md) - Auth token refresh fix
```

## Devlog File Format

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
- 다음에 비슷한 작업 시 참고할 점

## 변경 파일 (Changed Files)
- `path/to/file.ts` — 변경 설명
```

### Step 6: Update Top-Level logs/README.md

After any devlog creation, also update the top-level logs index at `$PROJECT_ROOT/logs/README.md`.
Follow the same format defined in the TSG skill's Step 8. Scan all sections (troubleshooting, devlog, pr-verify) and regenerate the full index.

## Key Principles

- **시행착오 과정이 핵심** — 최종 결과만이 아니라 중간 과정을 기록
- **사람이 읽기 좋은 문서가 먼저** — Claude는 참조만 한다
- **Progressive disclosure** — README.md 인덱스 → frontmatter 스캔 → body drill-down
- **반드시 사용자 확인 후 저장** — draft 보여준 뒤 확인받고 저장
- **ID는 재사용하지 않음** — 삭제해도 번호 건너뜀
- **Flat directory** — task_type frontmatter로 필터링, 카테고리 디렉토리 불필요
- **README.md는 매 작업 후 자동 갱신** — 항상 최신 상태 유지
- **사용자 검증(user_validation)은 메트릭과 별개** — autocode 등에서 메트릭 개선이 되어도 사용자가 방향을 거부하면 rejected로 기록
