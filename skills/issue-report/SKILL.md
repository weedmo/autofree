---
name: issue-report
description: "제조 현장 이슈 문서화 — 비정형 텍스트(대화, 메모, 에러 로그)를 구조화된 트러블슈팅 문서로 변환. /issue-report로 문서 생성, /issue-report <target>으로 특정 Notion 페이지에 작성."
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
| `/issue-report <target> <텍스트>` | 지정한 Notion 페이지/DB 안에 이슈 생성 | Required |

### Target Parameter

`<target>`은 Notion 페이지 또는 데이터베이스 이름이다. 예:
- `/issue-report tommoro 로봇 팔 에러` → "tommoro" Notion 페이지/DB에 이슈 생성
- `/issue-report 생산이슈 cell003 토크 미인가` → "생산이슈" Notion 페이지/DB에 이슈 생성

**Target 판별 규칙**:
- 첫 번째 단어를 target 후보로 간주
- `mcp__notion__notion-search`로 해당 이름의 페이지/DB를 검색
- 매칭되는 Notion 페이지/DB가 있으면 → target으로 확정, 나머지를 이슈 텍스트로 처리
- 매칭 없으면 → target이 아닌 일반 텍스트로 간주, 전체를 이슈 텍스트로 처리

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
- `<첫 단어> <나머지 텍스트>` → **Target resolution** (Step 1A)
- `<텍스트>` (single word or target resolution failed) → **Record from text** (Step 2, using provided text)

### Step 1A: Target Resolution

When the input has 2+ words and the first word is not a reserved subcommand (`search`, `list`):

1. Extract the first word as `target_candidate`
2. Use `mcp__notion__notion-search` to search for `target_candidate`
3. **If a matching Notion page or database is found**:
   - Store the matched page/DB ID as `notion_target_id` and name as `notion_target_name`
   - Use the remaining text (after the first word) as the issue text
   - Continue to Step 2 with `notion_target` set
   - When reaching Step 4 (output format), **auto-select Notion** and skip the format selection prompt — only ask for content confirmation
4. **If no match found**:
   - Treat the entire input (including the first word) as issue text
   - Continue to Step 2 without `notion_target` (normal flow)

### Step 2: Extract Information from Input

Analyze the conversation or provided text to extract:

**Required fields** (누락 시 사용자에게 질문):
- **증상**: 관찰된 동작, 에러 코드, 에러 메시지
- **조치**: 적용한 수정 또는 임시 대응 (미해결이면 `status: unresolved`)

**Auto-detect fields** (텍스트에서 자동 추출 시도):
- **cell**: 셀 번호 (예: cell003, Cell-5 → cell005)
- **severity**: critical/high/medium/low (에러 심각도에서 추론)
- **environment**: IP, SW 버전, FW 버전 등
- **tags**: 핵심 키워드 (장비명, 에러코드, SW 모듈명)

**Optional fields** (있으면 포함, 없으면 생략):
- **재발시 대처**: 반복 시 에스컬레이션 절차
- **재현 방법**: 재현 절차와 재현율
- **로그 및 자료**: 에러 로그, 영상/사진 링크
- **참고 자료**: 관련 버그 리포트, 포럼 글, 공식 문서 등 외부 링크. 입력 텍스트에서 URL을 자동 추출하고, 출처 명시된 사이트명도 검색하여 링크로 변환한다.
- **비고**: 기대 결과, 특이사항, 재발 방지책

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

2. Generate **title** using the pattern: `[현상] — [조건/원인]`
   - Example: `인터넷 끊김 — ASPM 활성 시 igc PCIe 링크 손실`
   - Example: `텔레옵 토크 미인가 — 서보 드라이버 타임아웃`
   - Keep concise, Korean, no emoji, no English labels

3. Generate a **slug** from the title (lowercase, hyphens, max 50 chars, ASCII transliteration of Korean)

3. Show the draft to the user:

   ```
   ## Issue Draft: {next_id}

   **Cell**: {cell} | **Severity**: {severity} | **Status**: {status}
   **Tags**: {tag1, tag2, ...}

   ### 증상
   - ...

   ### 조치
   ```bash
   # 조치한 순서대로 코드 블록으로 작성
   ...
   ```

   ### 재발시 대처
   - ...

   ---

   ### 이슈 정리
   ...

   ### 재현 방법
   1. ...

   ### 로그 및 자료
   - ...

   ### 참고 자료
   - [출처명](URL) — 간단한 설명
   - ...

   ### 비고
   - ...
   ```

4. **Wait for user confirmation** using AskUserQuestion:

   **If `notion_target` is set** (target was resolved in Step 1A):
   ```
   이 내용으로 "{notion_target_name}" Notion 페이지에 이슈를 생성할까요?
   (수정할 부분이 있으면 말씀해주세요)
   ```
   → On confirmation, execute **Step 4B** (Notion Output) directly.

   **Otherwise** (no target):
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

1. **If `notion_target` is set** (from Step 1A): use the already-resolved `notion_target_id` as the parent page/DB.
   **Otherwise**: Use `mcp__notion__notion-search` to find the target database (search for "이슈" or "Issue" database).
2. If no database/page found, create as standalone workspace page.
3. **MUST use `ReadMcpResourceTool` to fetch `notion://docs/enhanced-markdown-spec`** before writing content, to confirm available Notion-flavored Markdown syntax.
4. Convert body to **visually rich Notion-flavored Markdown** using these formatting rules:

   **General rules**:
   - Do NOT use emoji icons anywhere (no callout icons, no heading icons, no status icons)
   - Do NOT use bilingual headers like "증상 (Symptoms)" — use Korean only: "증상"
   - Do NOT use "대응" or "즉시 대응" as section name — use "증상", "조치", "재발시 대처" directly
   - "해결 방법" → "조치" — 단계 번호(1단계, 2단계) 없이 조치한 순서대로 코드 블록으로 작성
   - Highlight truly important info with `<span color="yellow_bg">text</span>` (yellow background) instead of emoji

   **Severity badge** — Callout with color-coded background at the top (no icon):
   - critical → `<callout color="red_bg">`, high → `<callout color="orange_bg">`
   - medium → `<callout color="yellow_bg">`, low → `<callout color="green_bg">`

   **Status** — Inside the severity callout:
   - resolved → `<span color="green">Resolved</span>`, unresolved → `<span color="red">Unresolved</span>`

   **Frontmatter info** — Use `<columns>` layout for metadata (2열)

   **조치/재발시 대처** — callout이나 `###` 소제목 사용하지 않음. `- 설명` 글 다음에 바로 코드 블록이 오는 패턴으로 작성. 항상 **글 → 코드** 쌍으로 구성

   **Code blocks** — Use fenced code with language (```bash ... ```).

   **상세 기록** — Toggle heading으로 접기/펼치기:
   ```
   ## 상세 기록 {toggle="true" color="gray"}
   ```

   **참고 자료** — Each reference as `[Title](URL)` — Notion auto-renders link previews.

   **Tables** — Use `<table>` with `header-row="true"` and column colors for structured data (발생 이력, 원인 분석 등).

   **Dividers** — Use `---` between 대응 section and 상세 기록.

   **Color usage**:
   - Error codes/logs: inline `code` formatting
   - Key warnings/important info: `<span color="yellow_bg">text</span>` (yellow highlight)
   - Status green/red for resolved/unresolved

5. Use `mcp__notion__notion-create-pages` to create the page (no icon).
6. Display the created page URL.

#### Step 4C: HTML Output

1. Convert the markdown document to styled HTML using this structure:
   - Clean, professional styling with CSS (print-friendly)
   - Color-coded severity badge (critical=red, high=orange, medium=yellow, low=green)
   - Status badge (resolved=green, unresolved=red)
   - Collapsible "Investigation Detail" section
   - Monospace font for error codes and logs
2. Write to `$ISSUE_DIR/{next_id}-{slug}.html`.

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

## 증상
- 텔레옵 버튼 클릭 시 UI 활성화 표시되나 실제 토크 미인가
- Error Code: `E-402` (서보 드라이버 타임아웃)

## 조치
```bash
# 캘리브레이션 초기화
calibrate --reset

# 서보 드라이버 콜드 부팅
systemctl restart servo-driver

# 정상 동작 확인
servo-status --check
```

## 재발시 대처
- 동일 증상 3회 반복 시 하네스 교체
- 네트워크 대역폭 모니터링 확인

---

## 상세 기록

### 이슈 정리
문제 배경, 발견 경위, 근본 원인 분석

### 재현 방법
1. Dataset Manager 실행 → 로봇 연결
2. Record 버튼 클릭
3. 약 2초 후 화면 멈춤 (재현율: 100%)

### 로그 및 자료
- `[에러 로그 텍스트/링크]`
- `[영상/사진 링크]`

### 참고 자료
- [출처명](URL) — 관련 내용 요약

### 비고
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

## 증상
- Record 버튼 클릭 후 약 2초 뒤 화면 멈춤
- CPU 사용률 100% 고정

## 시도한 방법
1. Dataset Manager 재시작 → 동일 증상 반복
2. 다른 Cell에서 테스트 → Cell003에서는 정상
3. 네트워크 케이블 교체 → 효과 없음

## 현재 상태
- Cell005에서만 재현, 네트워크 스위치 문제 의심
- 네트워크 팀 확인 대기 중

---

## 상세 기록

### 이슈 정리
문제 배경, 발견 경위

### 재현 방법
1. ...

### 로그 및 자료
- ...

### 참고 자료
- [출처명](URL) — 관련 내용 요약

### 비고
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
| `https?://\S+` | reference URLs (auto-extract) |
| `Bug \d+`, `Issue #\d+`, `CVE-\d+-\d+` | bug tracker / CVE references |
| Site name mentions (e.g. "The Mail Archive", "Proxmox forum") | search for actual URL via WebSearch if not provided |

## Key Principles

- **Fix-First**: 조치 정보가 항상 최상단 — 현장 엔지니어가 스크롤 없이 해결책 확인
- **YAML frontmatter**: 환경 정보 정형화로 자동 파싱/검색/통계 용이
- **조치/상세 구분선**: 현장 엔지니어(조치) vs R&D 팀(상세 기록) 각각 필요한 부분만 읽기
- **Resolved 문서는 반드시 사용자 확인** 후 저장
- **누락 정보는 질문으로 보완** — 추측으로 채우지 않음
- **ID 형식**: `ISSUE-YYYY-NNN` (연도별 시퀀스, 재사용 안 함)
- **TSG 스킬과 독립적** — TSG는 코드 이슈, issue-report는 제조 현장 이슈
