---
name: skill-recommend
description: "Skill recommender — automatically suggests the best-matching skills for the user's task. Triggers when the user gives a non-trivial task without explicitly invoking a skill (no / prefix). Analyzes the request, matches against all available skills, and presents up to 5 recommendations for the user to choose from. Use this skill PROACTIVELY whenever the user describes a task that could benefit from a specialized skill but didn't invoke one. Do NOT trigger for simple questions, greetings, or single-step tasks that don't need skills."
---

# Skill Recommend — Automatic Skill Router

When the user describes a task without invoking a specific skill, analyze the request and recommend the most relevant skills. This helps users discover and leverage the full skill ecosystem without memorizing slash commands.

## When to Trigger

- User gives a multi-step or specialized task without a `/` prefix
- Task clearly maps to one or more available skills
- User seems unaware of a skill that would help

## When NOT to Trigger

- User already invoked a skill with `/command`
- Simple questions or greetings ("hello", "what is X?")
- Trivial single-step tasks (read a file, check git status)
- User explicitly said "just do it" or similar — skip recommendation and execute directly

## Procedure

### Step 1: Analyze the Request

Read the user's prompt and extract:
- **Task type**: coding, documentation, review, deployment, research, debugging, etc.
- **Complexity**: single-step vs multi-step
- **Domain**: language-specific, infrastructure, data, ML, design, etc.
- **Keywords**: file types (.pdf, .xlsx), frameworks, patterns mentioned

### Step 2: Match Against Available Skills

Scan the available skills from the system context (the skill list in system-reminder).
Score each skill by relevance:
- **Direct match**: task explicitly maps to skill description (e.g., "make a PDF" → pdf skill)
- **Workflow match**: task benefits from a structured workflow (e.g., "implement feature" → tdd, plan)
- **Quality match**: task would benefit from review/verification (e.g., code changes → code-reviewer, security-review)

### Step 3: Present Recommendations

Show up to 5 skills, ranked by relevance. Use this exact format:

```
이 작업에 추천하는 스킬:

1. /skill-name — 한 줄 설명 (추천 이유)
2. /skill-name — 한 줄 설명 (추천 이유)
3. /skill-name — 한 줄 설명 (추천 이유)

0. 스킬 없이 바로 진행

번호를 선택하세요.
```

Guidelines for recommendations:
- Rank by how well the skill fits the specific task, not general popularity
- Include the plugin prefix only when disambiguation is needed (e.g., `weed-harness:commit` vs `everything-claude-code:commit` — but if only one exists, just use `commit`)
- Keep descriptions in Korean, matching user's language
- The "0" option always exists — never force a skill on the user
- If only 1-2 skills are relevant, show only those — don't pad to 5

### Step 4: Execute the Chosen Skill

When the user picks a number:
- Invoke the selected skill using the Skill tool
- Pass the original user prompt as context
- If user picks "0", proceed without any skill

## Matching Heuristics

These patterns help identify which skills to recommend:

| User Signal | Likely Skills |
|------------|---------------|
| "만들어줘", "구현", "개발" (implementation) | `everything-claude-code:tdd`, `everything-claude-code:plan`, `autocode` |
| "리뷰", "검토" (review) | `everything-claude-code:code-reviewer`, `everything-claude-code:security-review` |
| ".pdf", ".xlsx", ".docx", ".pptx" (file types) | `document-skills:pdf`, `document-skills:xlsx`, `document-skills:docx`, `document-skills:pptx` |
| "커밋", "PR" (git workflow) | `commit`, `pr-ready` |
| "에러", "버그", "안돼" (debugging) | `tsg` |
| "테스트" (testing) | `everything-claude-code:tdd`, `test-validation` |
| "문서", "README" (documentation) | `document-skills:doc-coauthoring` |
| "연구", "논문" (research) | `weed-cowork:paper-review`, `everything-claude-code:deep-research` |
| "최적화", "성능" (optimization) | `autocode` |
| "슬라이드", "발표" (presentation) | `document-skills:pptx`, `everything-claude-code:frontend-slides` |
| "이슈", "현장" (issue report) | `weed-cowork:issue-report` |
| "API", "Claude API" | `document-skills:claude-api` |
| "에이전트", "agent" | `agent-development` |
| ML, training, model | `auto_research` |
| "계획", "설계" (planning) | `everything-claude-code:plan`, `everything-claude-code:blueprint` |
| "보안" (security) | `everything-claude-code:security-review`, `everything-claude-code:security-scan` |

These are starting points — always read the full skill descriptions from context to find the best match for the specific task.

## Key Principles

- **Speed over completeness** — recommend fast, don't over-analyze
- **Respect user autonomy** — always include the "skip" option
- **Context-aware** — consider the project type, recent conversation, and user preferences
- **Don't over-recommend** — if no skill clearly fits, say so and proceed directly
- **Plugin-aware** — know which plugin provides each skill to avoid recommending duplicates
