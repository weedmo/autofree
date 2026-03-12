---
name: tsg
description: "Troubleshooting Guide (TSG) — 코드 이슈 해결 과정을 체계적으로 기록/검색/관리. 에러 해결 후 /tsg로 기록, /tsg search로 검색, /tsg unresolved로 미해결 이슈 추적, /tsg resolve로 해결 병합."
---

# TSG — Troubleshooting Guide

코드 이슈 해결 후 "어떤 문제였고, 어떻게 해결했는지"를 체계적으로 기록하여:
- **사람**: 잘 정리된 문서를 읽고 검색하고 학습
- **Claude**: 유사 이슈 재발 시 기존 TSG를 참조하여 빠르게 해결

핵심 원칙: **사람이 읽기 좋은 문서가 먼저**, Claude는 그걸 참조만 한다.

## Subcommands

| Command | Action | User Confirmation |
|---------|--------|-------------------|
| `/tsg` (no args) | 현재 대화에서 이슈 감지, 기록 여부 질문 | Required |
| `/tsg search <keyword>` | 기존 TSG 검색 (frontmatter tags + title) | Not needed |
| `/tsg list` | 전체 TSG 목록 (상태별 그룹) | Not needed |
| `/tsg unresolved` | 미해결 이슈 자동 기록 | Not needed (auto) |
| `/tsg resolve <TSG-ID>` | 미해결 → 해결로 병합 | Required |

## Directory Structure

TSG files are stored per-project under `docs/troubleshooting/`:

```
<project-root>/docs/troubleshooting/
├── README.md                              ← Index (auto-generated/updated)
├── build/
│   └── TSG-001-webpack-memory-overflow.md
├── api/
│   └── TSG-002-stripe-webhook-timeout.md
└── database/
    └── TSG-003-prisma-migration-drift.md
```

## Procedure

### Step 0: Detect Project Root and TSG Directory

```
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
TSG_DIR="$PROJECT_ROOT/docs/troubleshooting"
```

If `$TSG_DIR` does not exist, create it along with `README.md` when first writing a TSG.

### Step 1: Parse Subcommand

Parse the user's input to determine which subcommand to execute:
- No args → **Record workflow** (Step 2A or 2B)
- `search <keyword>` → **Search workflow** (Step 3)
- `list` → **List workflow** (Step 4)
- `unresolved` → **Unresolved workflow** (Step 5)
- `resolve <TSG-ID>` → **Resolve workflow** (Step 6)

### Step 2A: Record Resolved Issue (`/tsg`)

1. Analyze the current conversation to extract:
   - **증상**: Error messages, observed behavior
   - **원인**: Root cause analysis
   - **해결**: Applied fix
   - **핵심 개념**: Technical concepts needed to understand
   - **재발 방지**: Prevention checklist
   - **tags**: Keywords for searchability

2. Determine **category** from the issue context (e.g., `build`, `api`, `database`, `config`, `auth`, `deploy`, `test`, `performance`, etc.)

3. Generate next **TSG ID**:
   ```bash
   # Find max existing ID across all subdirectories
   max_id=$(grep -rh '^id: TSG-' "$TSG_DIR"/*/TSG-*.md 2>/dev/null | sed 's/id: TSG-0*//' | sort -n | tail -1)
   next_id=$(printf "TSG-%03d" $((${max_id:-0} + 1)))
   ```

4. Generate a **slug** from the title (lowercase, hyphens, max 50 chars)

5. Show the draft to the user in this format:

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
   - Write the TSG file with frontmatter (see format below)
   - Update `README.md` index (Step 7)

### Step 2B: No Issue Detected

If no clear issue/resolution is found in the conversation:
```
현재 대화에서 기록할 만한 이슈를 찾지 못했습니다.
특정 이슈를 기록하고 싶다면 설명해주세요.
```

### Step 3: Search (`/tsg search <keyword>`)

1. Search across all TSG files in `$TSG_DIR`:
   ```bash
   # Search in frontmatter tags and titles
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

### Step 4: List (`/tsg list`)

1. If `$TSG_DIR` does not exist:
   - Create `$TSG_DIR` and an empty `README.md`
   - Display: `TSG 디렉토리를 생성했습니다. 아직 등록된 TSG가 없습니다.`
   - Return

2. Read `README.md` and display the Quick Search table.

3. If no TSGs exist: `등록된 TSG가 없습니다.`

### Step 5: Record Unresolved Issue (`/tsg unresolved`)

1. Analyze conversation to extract:
   - **증상**: Error messages, observed behavior
   - **시도한 방법**: Approaches tried and their results
   - **현재 상태**: Current situation
   - **tags**: Keywords

2. Generate next TSG ID and slug (same as Step 2A).

3. **Write immediately without confirmation**:
   - Create category directory if needed
   - Write TSG file with `status: unresolved` (see format below)
   - Update `README.md` index (Step 7)

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
   - 해결되면 `/tsg resolve {next_id}`로 업데이트하세요.
   ```

### Step 6: Resolve (`/tsg resolve <TSG-ID>`)

1. Find the existing TSG file:
   ```bash
   find "$TSG_DIR" -name "${TSG_ID}*" -type f
   ```

2. If not found: `{TSG_ID}를 찾을 수 없습니다. /tsg list로 확인해주세요.`

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
   - Update `README.md` index (Step 7)
   - Find and complete related task if exists

### Step 7: Update README.md Index

After any TSG creation or modification, regenerate the index:

1. Scan all `TSG-*.md` files in `$TSG_DIR` subdirectories
2. Parse frontmatter from each file (id, status, severity, category, title, tags)
3. Write `README.md` with this structure:

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

## TSG File Formats

### Resolved TSG

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

### Unresolved TSG

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

## Key Principles

- **사람이 읽기 좋은 문서가 먼저** — Claude는 참조만 한다
- **Progressive disclosure** — README.md 인덱스 → frontmatter 스캔 → body drill-down
- **Resolved TSG는 반드시 사용자 확인** 후 저장
- **Unresolved TSG는 자동 저장** — 빠르게 기록하고 나중에 resolve
- **ID는 재사용하지 않음** — 삭제해도 번호 건너뜀
- **카테고리 디렉토리는 on-demand 생성** — 첫 TSG 작성 시 자동 생성
- **README.md는 매 작업 후 자동 갱신** — 항상 최신 상태 유지
