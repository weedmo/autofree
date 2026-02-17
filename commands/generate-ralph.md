---
description: Analyze project and generate Ralph loop-optimized MD files (PROMPT.md, fix_plan.md, AGENT.md)
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls *), Bash(git *), AskUserQuestion
argument-hint: [PRD file path or project description]
---

# /generate-ralph — Generate Ralph Configuration Files

You are generating configuration files for Ralph, an autonomous AI development loop.
Your goal: produce **three markdown files** that are fully customized for the current project, with zero placeholders or multi-option templates.

The user may provide a PRD file path, a project description, or nothing at all. Adapt accordingly.

---

## Phase 1: Silent Analysis (DO NOT ask questions yet)

Gather as much context as possible before asking the user anything.

### 1.1 Detect Project Stack
Use `Glob` to check for manifest files:
- `package.json`, `tsconfig.json`, `yarn.lock`, `pnpm-lock.yaml` → JavaScript/TypeScript
- `pyproject.toml`, `setup.py`, `requirements.txt`, `uv.lock` → Python
- `Cargo.toml` → Rust
- `go.mod` → Go
- `Gemfile` → Ruby
- `pom.xml`, `build.gradle` → Java/Kotlin

If found, use `Read` to extract:
- Project name
- Dependencies (frameworks, test libs, linters)
- Scripts (build, test, dev, start)

### 1.2 Read Existing Context
- `Read` README.md if it exists
- `Read` any file passed as argument (PRD, spec, requirements doc)
- `Read` existing `.ralph/PROMPT.md`, `.ralph/fix_plan.md`, `.ralph/AGENT.md` if they exist (to understand what to improve)
- `Read` any `docs/` or `specs/` markdown files (max 3 files)

### 1.3 Assess Project Maturity
- `Bash(git log --oneline -20 2>/dev/null || echo "no-git")` — commit count and recency
- `Bash(ls src/ 2>/dev/null || ls app/ 2>/dev/null || ls lib/ 2>/dev/null || echo "no-src")` — source file presence
- `Glob` for test files (`**/*.test.*`, `**/*.spec.*`, `**/test_*`, `**/tests/`)
- `Glob` for CI config (`.github/workflows/*`, `.gitlab-ci.yml`, `Jenkinsfile`)

### 1.4 Build Knowledge Map
After analysis, mentally evaluate what you know vs. don't know:

| Information | Source | Status |
|---|---|---|
| Project name | manifest / folder name | known / unknown |
| Project purpose | README / PRD / argument | known / unknown |
| Tech stack | manifest files | known / unknown |
| Build/test/run commands | package.json scripts etc. | known / unknown |
| Current state (greenfield vs. existing) | git log, src files | known / unknown |
| Priority features/tasks | PRD / issues / argument | known / unknown |
| Success criteria | PRD | known / unknown |

---

## Phase 2: Intelligent Questioning (ONLY ask what you couldn't detect)

Review your Knowledge Map. **Only ask about items marked "unknown".**

Rules:
- If the user provided a detailed PRD with tasks, skip all questions.
- Maximum 2 rounds of questions (use `AskUserQuestion`).
- Group related unknowns into a single question round.
- Always frame questions with what you already detected, so the user only fills gaps.

### Question Priority (ask highest priority unknowns first):

1. **Project purpose** — if no README, no PRD, and no argument provided:
   > "I detected a [TypeScript/Next.js] project named 'my-app'. What is this project? (e.g., 'E-commerce API with Stripe integration')"

2. **Priority features/tasks** — if no PRD, no issues, no fix_plan:
   > "What are the main features you want Ralph to build? List them in priority order."

3. **Build/test/run commands** — if no scripts detected in manifest:
   > "I couldn't detect build commands. How do you build, test, and run this project?"

4. **Current state** — if ambiguous (some files exist but unclear):
   > "I see [N] source files and [M] commits. Is this a working project that needs new features, or is it early stage?"

5. **Success criteria** — if no PRD:
   > "What does 'done' look like for this project?"

If everything is detected, proceed directly to Phase 3 with a brief summary of what you found.

---

## Phase 3: File Generation

Generate all three files. Write them to `.ralph/` directory.
Create `.ralph/` and its subdirectories if they don't exist.

### 3.1 Generate `.ralph/PROMPT.md`

Structure:
```
# Ralph Development Instructions

## Context
[Project-specific paragraph: name, purpose, stack, current state]

## Current Objectives
[Numbered list derived from project goals, NOT generic]

## Key Principles
[Keep these standard Ralph principles]

## Testing Guidelines (CRITICAL)
[Keep standard - 20% effort cap]

## Execution Guidelines
[Keep standard]

## Status Reporting (CRITICAL - Ralph needs this!)
[INCLUDE THE ENTIRE RALPH_STATUS BLOCK BELOW VERBATIM]

## Exit Scenarios (Specification by Example)
[INCLUDE ALL 6 SCENARIOS BELOW VERBATIM]

## File Structure
[Customize to actual project structure]

## Current Task
[Reference fix_plan.md]
```

**CRITICAL: The following RALPH_STATUS block and Exit Scenarios MUST be included verbatim in every generated PROMPT.md. Do NOT summarize, shorten, or omit any part.**

#### RALPH_STATUS Block (copy exactly):

````
## Status Reporting (CRITICAL - Ralph needs this!)

**IMPORTANT**: At the end of your response, ALWAYS include this status block:

```
---RALPH_STATUS---
STATUS: IN_PROGRESS | COMPLETE | BLOCKED
TASKS_COMPLETED_THIS_LOOP: <number>
FILES_MODIFIED: <number>
TESTS_STATUS: PASSING | FAILING | NOT_RUN
WORK_TYPE: IMPLEMENTATION | TESTING | DOCUMENTATION | REFACTORING
EXIT_SIGNAL: false | true
RECOMMENDATION: <one line summary of what to do next>
---END_RALPH_STATUS---
```

### When to set EXIT_SIGNAL: true

Set EXIT_SIGNAL to **true** when ALL of these conditions are met:
1. All items in fix_plan.md are marked [x]
2. All tests are passing (or no tests exist for valid reasons)
3. No errors or warnings in the last execution
4. All requirements from specs/ are implemented
5. You have nothing meaningful left to implement

### Examples of proper status reporting:

**Example 1: Work in progress**
```
---RALPH_STATUS---
STATUS: IN_PROGRESS
TASKS_COMPLETED_THIS_LOOP: 2
FILES_MODIFIED: 5
TESTS_STATUS: PASSING
WORK_TYPE: IMPLEMENTATION
EXIT_SIGNAL: false
RECOMMENDATION: Continue with next priority task from fix_plan.md
---END_RALPH_STATUS---
```

**Example 2: Project complete**
```
---RALPH_STATUS---
STATUS: COMPLETE
TASKS_COMPLETED_THIS_LOOP: 1
FILES_MODIFIED: 1
TESTS_STATUS: PASSING
WORK_TYPE: DOCUMENTATION
EXIT_SIGNAL: true
RECOMMENDATION: All requirements met, project ready for review
---END_RALPH_STATUS---
```

**Example 3: Stuck/blocked**
```
---RALPH_STATUS---
STATUS: BLOCKED
TASKS_COMPLETED_THIS_LOOP: 0
FILES_MODIFIED: 0
TESTS_STATUS: FAILING
WORK_TYPE: DEBUGGING
EXIT_SIGNAL: false
RECOMMENDATION: Need human help - same error for 3 loops
---END_RALPH_STATUS---
```

### What NOT to do:
- Do NOT continue with busy work when EXIT_SIGNAL should be true
- Do NOT run tests repeatedly without implementing new features
- Do NOT refactor code that is already working fine
- Do NOT add features not in the specifications
- Do NOT forget to include the status block (Ralph depends on it!)
````

#### Exit Scenarios (copy exactly):

````
## Exit Scenarios (Specification by Example)

Ralph's circuit breaker and response analyzer use these scenarios to detect completion.
Each scenario shows the exact conditions and expected behavior.

### Scenario 1: Successful Project Completion
**Given**:
- All items in .ralph/fix_plan.md are marked [x]
- Last test run shows all tests passing
- No errors in recent logs/
- All requirements from .ralph/specs/ are implemented

**When**: You evaluate project status at end of loop

**Then**: You must output:
```
---RALPH_STATUS---
STATUS: COMPLETE
TASKS_COMPLETED_THIS_LOOP: 1
FILES_MODIFIED: 1
TESTS_STATUS: PASSING
WORK_TYPE: DOCUMENTATION
EXIT_SIGNAL: true
RECOMMENDATION: All requirements met, project ready for review
---END_RALPH_STATUS---
```

**Ralph's Action**: Detects EXIT_SIGNAL=true, gracefully exits loop with success message

---

### Scenario 2: Test-Only Loop Detected
**Given**:
- Last 3 loops only executed tests (npm test, bats, pytest, etc.)
- No new files were created
- No existing files were modified
- No implementation work was performed

**When**: You start a new loop iteration

**Then**: You must output:
```
---RALPH_STATUS---
STATUS: IN_PROGRESS
TASKS_COMPLETED_THIS_LOOP: 0
FILES_MODIFIED: 0
TESTS_STATUS: PASSING
WORK_TYPE: TESTING
EXIT_SIGNAL: false
RECOMMENDATION: All tests passing, no implementation needed
---END_RALPH_STATUS---
```

**Ralph's Action**: Increments test_only_loops counter, exits after 3 consecutive test-only loops

---

### Scenario 3: Stuck on Recurring Error
**Given**:
- Same error appears in last 5 consecutive loops
- No progress on fixing the error
- Error message is identical or very similar

**When**: You encounter the same error again

**Then**: You must output:
```
---RALPH_STATUS---
STATUS: BLOCKED
TASKS_COMPLETED_THIS_LOOP: 0
FILES_MODIFIED: 2
TESTS_STATUS: FAILING
WORK_TYPE: DEBUGGING
EXIT_SIGNAL: false
RECOMMENDATION: Stuck on [error description] - human intervention needed
---END_RALPH_STATUS---
```

**Ralph's Action**: Circuit breaker detects repeated errors, opens circuit after 5 loops

---

### Scenario 4: No Work Remaining
**Given**:
- All tasks in fix_plan.md are complete
- You analyze .ralph/specs/ and find nothing new to implement
- Code quality is acceptable
- Tests are passing

**When**: You search for work to do and find none

**Then**: You must output:
```
---RALPH_STATUS---
STATUS: COMPLETE
TASKS_COMPLETED_THIS_LOOP: 0
FILES_MODIFIED: 0
TESTS_STATUS: PASSING
WORK_TYPE: DOCUMENTATION
EXIT_SIGNAL: true
RECOMMENDATION: No remaining work, all .ralph/specs implemented
---END_RALPH_STATUS---
```

**Ralph's Action**: Detects completion signal, exits loop immediately

---

### Scenario 5: Making Progress
**Given**:
- Tasks remain in .ralph/fix_plan.md
- Implementation is underway
- Files are being modified
- Tests are passing or being fixed

**When**: You complete a task successfully

**Then**: You must output:
```
---RALPH_STATUS---
STATUS: IN_PROGRESS
TASKS_COMPLETED_THIS_LOOP: 3
FILES_MODIFIED: 7
TESTS_STATUS: PASSING
WORK_TYPE: IMPLEMENTATION
EXIT_SIGNAL: false
RECOMMENDATION: Continue with next task from .ralph/fix_plan.md
---END_RALPH_STATUS---
```

**Ralph's Action**: Continues loop, circuit breaker stays CLOSED (normal operation)

---

### Scenario 6: Blocked on External Dependency
**Given**:
- Task requires external API, library, or human decision
- Cannot proceed without missing information
- Have tried reasonable workarounds

**When**: You identify the blocker

**Then**: You must output:
```
---RALPH_STATUS---
STATUS: BLOCKED
TASKS_COMPLETED_THIS_LOOP: 0
FILES_MODIFIED: 0
TESTS_STATUS: NOT_RUN
WORK_TYPE: IMPLEMENTATION
EXIT_SIGNAL: false
RECOMMENDATION: Blocked on [specific dependency] - need [what's needed]
---END_RALPH_STATUS---
```

**Ralph's Action**: Logs blocker, may exit after multiple blocked loops
````

### 3.2 Generate `.ralph/fix_plan.md`

**Task Sizing Guide:**
- **SMALL** (1 loop): Single function, config change, simple bug fix
- **MEDIUM** (2 loops): Feature with tests, API endpoint + handler
- **LARGE** (3 loops): Multi-file feature, integration with external service
- **TOO BIG** (must split): Anything bigger than 3 loops

**Rules:**
- Break large features into sub-tasks sized for 1-3 Ralph loops each
- Every task: starts with a verb, names the target, implies completion criteria
- Use indented sub-tasks for features that need decomposition
- Use `- [ ]` checkbox format (Ralph's regex: `^[[:space:]]*- \[`)
- Include `## High Priority`, `## Medium Priority`, `## Low Priority`, `## Completed` sections

**BAD examples (too vague):**
```
- [ ] Implement core business logic
- [ ] Add error handling
- [ ] Set up basic project structure
```

**GOOD examples (specific, actionable):**
```
## High Priority
- [ ] Implement user authentication
  - [ ] Add JWT token generation and validation utility in src/auth/jwt.ts
  - [ ] Create password hashing with bcrypt in src/auth/password.ts
  - [ ] Build POST /api/auth/login endpoint with email+password
  - [ ] Build POST /api/auth/register endpoint with validation
  - [ ] Add auth middleware for protected routes
- [ ] Create product catalog API
  - [ ] Define Product schema with Prisma (name, price, description, images)
  - [ ] Build GET /api/products with pagination and filtering
  - [ ] Build POST /api/products (admin only)
  - [ ] Build PUT /api/products/:id (admin only)

## Medium Priority
- [ ] Add input validation with Zod schemas for all endpoints
- [ ] Implement rate limiting middleware (100 req/min per IP)
- [ ] Add structured logging with pino

## Low Priority
- [ ] Add OpenAPI/Swagger documentation generation
- [ ] Implement response caching with Redis

## Completed
- [x] Project enabled for Ralph
```

### 3.3 Generate `.ralph/AGENT.md`

**Rules:**
- ONLY include commands for the detected stack. Do NOT list alternatives.
- Must contain at least 3 code blocks (build, test, run).
- No multi-option placeholders like `npm install / pip install / cargo build`.
- If a command wasn't detected, use a reasonable default for the detected stack.

**Structure:**
```markdown
# Agent Build Instructions

## Project Setup
\`\`\`bash
[single stack-specific install command]
\`\`\`

## Running Tests
\`\`\`bash
[single stack-specific test command]
\`\`\`

## Build Commands
\`\`\`bash
[single stack-specific build command]
\`\`\`

## Development Server
\`\`\`bash
[single stack-specific dev/run command]
\`\`\`

## Key Learnings
- [project-specific note if any, otherwise leave placeholder for Ralph to fill]
```

---

## Phase 4: Validation

After writing all three files, read them back and verify:

### 4.1 PROMPT.md Checks
- [ ] Contains `---RALPH_STATUS---` marker
- [ ] Contains `EXIT_SIGNAL:` instruction
- [ ] Contains `---END_RALPH_STATUS---` marker
- [ ] References `fix_plan.md`
- [ ] Project name is NOT `[YOUR PROJECT NAME]` placeholder
- [ ] Contains all 6 Exit Scenarios

### 4.2 fix_plan.md Checks
- [ ] Uses `- [ ]` checkbox format
- [ ] Has `## High Priority` section
- [ ] Has `## Medium Priority` section
- [ ] Has `## Low Priority` section
- [ ] Has at least 5 actionable tasks
- [ ] No generic phrases: check that none of these appear exactly:
  - "Implement core business logic"
  - "Set up basic project structure"
  - "Add error handling and validation"
  - "Define core data structures"

### 4.3 AGENT.md Checks
- [ ] Contains at least 3 code blocks (``` markers)
- [ ] No multi-option lines containing " / " or " or " between commands
- [ ] Commands match detected stack

### 4.4 Report Results
After validation, report to the user:
- Files created (with paths)
- Task count in fix_plan.md
- Any validation warnings
- Suggestion: "Run `ralph --monitor` to start the autonomous loop"

---

## Important Notes

- Always create `.ralph/specs/`, `.ralph/examples/`, `.ralph/logs/`, `.ralph/docs/generated/` directories alongside the files.
- If `.ralph/` files already exist, ask the user before overwriting.
- The RALPH_STATUS block format is a **contract** between Ralph and Claude. Changing it breaks exit detection.
- The `$USER_ARGUMENT` variable contains whatever the user passed after `/generate-ralph`.
