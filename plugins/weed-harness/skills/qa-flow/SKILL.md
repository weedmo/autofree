---
name: qa-flow
description: "Full QA pipeline orchestrator: browse → qa/qa-only → investigate → review → ship. Chains gstack QA skills into a complete workflow with automatic escalation. Use /qa-flow for end-to-end QA, /qa-flow report for report-only mode."
---

# QA Flow — End-to-End QA Pipeline

Orchestrates the full QA workflow by chaining related skills in the correct order.
Handles escalation between phases automatically.

## When to Use

- Full QA cycle on a web application (find bugs → fix → review → ship)
- Report-only QA (find bugs → report)
- Post-fix verification after debugging

## Modes

| Command | Mode | Skills Chain |
|---------|------|-------------|
| `/qa-flow <url>` | Full | browse → qa → review → ship |
| `/qa-flow report <url>` | Report-only | browse → qa-only |
| `/qa-flow verify <url>` | Post-fix | browse → qa-only (re-check) |

## Procedure

### Phase 1: Pre-flight

1. Check if cookies are needed for the target URL:
   - Authenticated page? → Invoke `/setup-browser-cookies` first
   - Public page? → Skip
2. Determine QA tier from user intent:
   - "quick check" → Quick (critical/high only)
   - Default → Standard (+ medium)
   - "thorough" / "exhaustive" → Exhaustive (+ cosmetic)

### Phase 2: Discovery (browse)

Invoke `/browse` to establish baseline:
```
browse <url> --snapshot
```
- Capture initial state screenshot
- Note console errors, network failures
- Identify key user flows to test

### Phase 3: QA Execution

**Full mode** → Invoke `/qa`:
- Finds bugs, fixes them, commits each fix atomically
- Before/after screenshots for each fix

**Report-only mode** → Invoke `/qa-only`:
- Structured report with health score
- Screenshots and repro steps
- No code changes

### Phase 4: Root Cause Analysis (if needed)

If `/qa` encounters a bug it cannot fix in 2 attempts:
1. Invoke `/investigate` on the specific bug
2. `/investigate` performs 4-phase root cause analysis
3. Return fix to `/qa` for verification

### Phase 5: Health Check

After all fixes are applied:
```
Invoke /health
```
- Compare before/after code quality scores
- Ensure fixes didn't degrade overall health

### Phase 6: Code Review (Full mode only)

Invoke `/review` on the changes:
- SQL safety, trust boundary violations
- Structural issues in the diff
- If issues found → fix immediately (auto-fix policy) → re-review

### Phase 7: Ship (Full mode only)

If review passes and user confirms:
1. Invoke `/ship` to create PR
2. Report PR URL to user

### Phase 8: Learnings

Invoke `/learn` to save any patterns discovered during QA:
- Common bug patterns in this project
- Areas prone to regression

## Escalation Rules

| Situation | Action |
|-----------|--------|
| Bug unfixable after 2 attempts | Escalate to `/investigate` |
| `/investigate` can't find root cause | STOP, report to user |
| Review finds issues | Auto-fix, re-review (max 2 cycles) |
| Health score dropped | STOP, report regression to user |
| 3+ phases blocked | STOP, full status report to user |

## Output

At completion, report:
1. Bugs found / fixed / remaining
2. Health score before → after
3. PR URL (if shipped)
4. Learnings saved
