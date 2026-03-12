---
name: issue-report
description: "제조 현장 이슈 문서화 — 비정형 텍스트(대화, 메모, 에러 로그)를 구조화된 트러블슈팅 문서로 변환. /issue-report로 문서 생성, search로 검색, list로 목록 조회."
---

# Issue Report — 제조 현장 이슈 문서화

로보틱스/AI 제조 환경에서 비정형 이슈 텍스트(대화, 메모, 에러 로그 등)를 구조화된 트러블슈팅 문서로 변환한다.

- **입력**: 자유 형식의 이슈 설명 (한국어, 영어, 혼합)
- **출력**: YAML frontmatter + Fix-First 본문 구조의 문서
- **저장**: Markdown, Notion, HTML 중 사용자 선택

핵심 원칙: **즉시 대응(Quick Response) 정보가 최상단** — 다운타임 비용 최소화.

## Subcommands

| Command | Action | User Confirmation |
|---------|--------|-------------------|
| `/issue-report` (no args) | 현재 대화에서 이슈 추출, 문서 생성 | Required |
| `/issue-report <텍스트>` | 입력 텍스트로 이슈 문서 생성 | Required |
| `/issue-report search <keyword>` | 기존 이슈 문서 검색 | Not needed |
| `/issue-report list` | 전체 이슈 목록 조회 | Not needed |

## Directory Structure

이슈 문서는 `~/issue_docs/`에 저장된다:

```
~/issue_docs/
├── ISSUE-2026-001-teleop-torque-failure.md
├── ISSUE-2026-002-dataset-manager-freeze.md
└── ISSUE-2026-003-camera-sync-delay.html
```

## Procedure

### Step 0: Detect Issue Docs Directory

```
ISSUE_DIR="$HOME/issue_docs"
```

If `$ISSUE_DIR` does not exist, create it when first writing a document.

### Step 1: Parse Subcommand

Parse the user's input to determine which subcommand to execute:
- No args → **Record workflow** (Step 2)
- `<텍스트>` (not a subcommand) → **Record from text** (Step 2, using provided text)
- `search <keyword>` → **Search workflow** (Step 5)
- `list` → **List workflow** (Step 6)

### Step 2: Extract Information from Input

Analyze the conversation or provided text to extract:

**Required fields** (누락 시 사용자에게 질문):
- **증상 (Symptoms)**: 관찰된 동작, 에러 코드, 에러 메시지
- **해결 방법 (Solution)**: 적용한 수정 또는 임시 대응 (미해결이면 `status: unresolved`)

**Auto-detect fields** (텍스트에서 자동 추출 시도):
- **cell**: 셀 번호 (예: cell003, Cell-5 → cell005)
- **severity**: critical/high/medium/low (에러 심각도에서 추론)
- **environment**: IP, SW 버전, FW 버전 등
- **tags**: 핵심 키워드 (장비명, 에러코드, SW 모듈명)

**Optional fields** (있으면 포함, 없으면 생략):
- **재발시 대처 (If Recurs)**: 반복 시 에스컬레이션 절차
- **재현 방법 (Reproduction Steps)**: 재현 절차와 재현율
- **로그 및 자료 (Logs & Evidence)**: 에러 로그, 영상/사진 링크
- **비고 (Notes)**: 기대 결과, 특이사항, 재발 방지책

### Step 3: Ask for Missing Required Information

If required fields are missing, use AskUserQuestion to ask. Example:

```
이슈 문서를 작성하려면 추가 정보가 필요합니다:

1. **증상**: 구체적인 에러 메시지나 관찰된 동작이 있나요?
2. **해결 방법**: 어떻게 해결했나요? (미해결이면 "미해결"이라고 알려주세요)
3. **셀 번호**: 어느 셀에서 발생했나요?
```

Only ask about genuinely missing information — do not ask about optional fields unless context suggests they exist.

### Step 4: Generate Document and Ask for Output Format

1. Generate next **Issue ID**:
   ```bash
   YEAR=$(date +%Y)
   max_id=$(ls "$ISSUE_DIR"/ISSUE-${YEAR}-*.md "$ISSUE_DIR"/ISSUE-${YEAR}-*.html 2>/dev/null | \
     sed "s/.*ISSUE-${YEAR}-0*//" | sed 's/-.*//' | sort -n | tail -1)
   next_id=$(printf "ISSUE-${YEAR}-%03d" $((${max_id:-0} + 1)))
   ```

2. Generate a **slug** from the title (lowercase, hyphens, max 50 chars, ASCII transliteration of Korean)

3. Show the draft to the user:

   ```
   ## Issue Draft: {next_id}

   **Cell**: {cell} | **Severity**: {severity} | **Status**: {status}
   **Tags**: {tag1, tag2, ...}

   ### 증상 (Symptoms)
   - ...

   ### 해결 방법 (Solution)
   1. ...

   ### 재발시 대처 (If Recurs)
   - ...

   ---

   ### 이슈 정리 (Issue Summary)
   ...

   ### 재현 방법 (Reproduction Steps)
   1. ...

   ### 로그 및 자료 (Logs & Evidence)
   - ...

   ### 비고 (Notes)
   - ...
   ```

4. **Wait for user confirmation** using AskUserQuestion:

   ```
   이 내용으로 이슈 문서를 생성할까요? (수정할 부분이 있으면 말씀해주세요)

   저장 방식을 선택해주세요:
   1. **Markdown** — ~/issue_docs/{next_id}-{slug}.md
   2. **Notion** — Notion 데이터베이스에 페이지 생성
   3. **HTML** — 인쇄 친화적 HTML ~/issue_docs/{next_id}-{slug}.html
   ```

5. On confirmation, execute the chosen output format (Step 4A, 4B, or 4C).

#### Step 4A: Markdown Output

Write the file using the template below to `$ISSUE_DIR/{next_id}-{slug}.md`.

#### Step 4B: Notion Output

1. Use `mcp__notion__notion-search` to find the target database (search for "이슈" or "Issue" database).
2. If no database found, ask the user which database to use.
3. Map frontmatter fields to Notion properties:
   - `id` → Title property
   - `cell`, `severity`, `status` → Select properties
   - `tags` → Multi-select property
   - `created` → Date property
   - Environment info → Rich text property
4. Convert markdown body to Notion blocks.
5. Use `mcp__notion__notion-create-pages` to create the page.
6. Display the created page URL.

#### Step 4C: HTML Output

1. Convert the markdown document to styled HTML using this structure:
   - Clean, professional styling with CSS (print-friendly)
   - Color-coded severity badge (critical=red, high=orange, medium=yellow, low=green)
   - Status badge (resolved=green, unresolved=red)
   - Collapsible "Investigation Detail" section
   - Monospace font for error codes and logs
2. Write to `$ISSUE_DIR/{next_id}-{slug}.html`.

### Step 5: Search (`/issue-report search <keyword>`)

1. Search across all issue files in `$ISSUE_DIR`:
   - Use Grep to search YAML frontmatter tags, titles, and body content
   - Match against keyword in both Korean and English

2. Display results:
   ```
   ## Issue Search: "<keyword>"

   | ID | Status | Cell | Severity | Title |
   |----|--------|------|----------|-------|
   | ISSUE-2026-001 | resolved | cell003 | high | 텔레옵 토크 미인가 |
   ```

3. If no results: `"<keyword>"에 대한 이슈 문서를 찾지 못했습니다.`

### Step 6: List (`/issue-report list`)

1. If `$ISSUE_DIR` does not exist or is empty:
   - Display: `등록된 이슈 문서가 없습니다.`
   - Return

2. Scan all `ISSUE-*.md` and `ISSUE-*.html` files, parse frontmatter.

3. Display grouped by status:
   ```
   ## Issue Documents

   ### Unresolved
   | ID | Cell | Severity | Title | Created |
   |----|------|----------|-------|---------|
   | ISSUE-2026-002 | cell005 | critical | Dataset Manager 프리징 | 2026-03-10 |

   ### Resolved
   | ID | Cell | Severity | Title | Created |
   |----|------|----------|-------|---------|
   | ISSUE-2026-001 | cell003 | high | 텔레옵 토크 미인가 | 2026-03-08 |
   ```

## Document Template

```markdown
---
id: ISSUE-YYYY-NNN
cell: cell003
severity: high
status: resolved
created: 2026-03-12
tags: [RobotArm, Teleop, Torque]
environment:
  console_ip: 192.168.0.10
  arm:
    communicator: v1.2.0
    ffw: bg2_rev4
  amd:
    dataset_manager: v3.1.0
---

# [한줄 요약] 텔레옵 활성화 시 로봇 팔 토크 미인가

## 즉시 대응 (Quick Response)

### 증상 (Symptoms)
- 텔레옵 버튼 클릭 시 UI 활성화 표시되나 실제 토크 미인가
- Error Code: `E-402` (서보 드라이버 타임아웃)

### 해결 방법 (Solution)
1. 캘리브레이션 초기화
2. 서보 드라이버 콜드 부팅
3. 정상 동작 확인

### 재발시 대처 (If Recurs)
- 동일 증상 3회 반복 시 하네스 교체
- 네트워크 대역폭 모니터링 확인

---

## 상세 기록 (Investigation Detail)

### 이슈 정리 (Issue Summary)
문제 배경, 발견 경위, 근본 원인 분석

### 재현 방법 (Reproduction Steps)
1. Dataset Manager 실행 → 로봇 연결
2. Record 버튼 클릭
3. 약 2초 후 화면 멈춤 (재현율: 100%)

### 로그 및 자료 (Logs & Evidence)
- `[에러 로그 텍스트/링크]`
- `[영상/사진 링크]`

### 비고 (Notes)
- 기대 결과: 끊김 없이 데이터 저장
- 특이사항: Cell005에서는 정상 → 네트워크 문제 가능성
- 재발 방지: 매주 월요일 Network Health Check 실행
```

## Unresolved Document Template

For issues without a solution yet, use a simplified structure:

```markdown
---
id: ISSUE-YYYY-NNN
cell: cell005
severity: critical
status: unresolved
created: 2026-03-12
tags: [DatasetManager, Freeze, Recording]
environment:
  console_ip: 192.168.0.20
  amd:
    dataset_manager: v3.1.0
---

# [한줄 요약] Dataset Manager 녹화 중 프리징

## 즉시 대응 (Quick Response)

### 증상 (Symptoms)
- Record 버튼 클릭 후 약 2초 뒤 화면 멈춤
- CPU 사용률 100% 고정

### 시도한 방법 (Attempted Solutions)
1. Dataset Manager 재시작 → 동일 증상 반복
2. 다른 Cell에서 테스트 → Cell003에서는 정상
3. 네트워크 케이블 교체 → 효과 없음

### 현재 상태 (Current Status)
- Cell005에서만 재현, 네트워크 스위치 문제 의심
- 네트워크 팀 확인 대기 중

---

## 상세 기록 (Investigation Detail)

### 이슈 정리 (Issue Summary)
문제 배경, 발견 경위

### 재현 방법 (Reproduction Steps)
1. ...

### 로그 및 자료 (Logs & Evidence)
- ...

### 비고 (Notes)
- ...
```

## Information Extraction Patterns

When parsing unstructured input, look for these patterns:

| Pattern | Extraction Target |
|---------|-------------------|
| `cell\d+`, `Cell-?\d+`, `셀\d+` | cell field |
| `\d+\.\d+\.\d+\.\d+` | console_ip |
| `v\d+\.\d+\.\d+` | SW/FW version |
| `E-\d+`, `Error:`, `에러` | error code / symptoms |
| `해결`, `고침`, `fixed`, `solved` | solution markers |
| `재현`, `reproduce`, `반복` | reproduction info |
| `bg\d+_rev\d+` | firmware version |

## Key Principles

- **Fix-First**: 즉시 대응 정보가 항상 최상단 — 현장 엔지니어가 스크롤 없이 해결책 확인
- **YAML frontmatter**: 환경 정보 정형화로 자동 파싱/검색/통계 용이
- **Quick/Detail 구분선**: 현장 엔지니어(Quick) vs R&D 팀(Detail) 각각 필요한 부분만 읽기
- **Resolved 문서는 반드시 사용자 확인** 후 저장
- **누락 정보는 질문으로 보완** — 추측으로 채우지 않음
- **ID 형식**: `ISSUE-YYYY-NNN` (연도별 시퀀스, 재사용 안 함)
- **TSG 스킬과 독립적** — TSG는 코드 이슈, issue-report는 제조 현장 이슈
