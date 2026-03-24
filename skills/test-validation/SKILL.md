---
name: test-validation
description: "Test Validation — verify code fixes by running tests against before/after commits. Confirms FAIL-to-PASS pattern to validate both test quality and fix correctness. Use /test-validation to run. Integrates with TSG for issue context. Use whenever verifying bugfixes, testing refactors, or validating that test code properly catches the issue it was written for."
---

# Test Validation

Verify that a code fix actually resolves the issue by running tests against both the pre-fix and post-fix commits.

Core principle: **A correct test must FAIL on the old (broken) code and PASS on the new (fixed) code.**
Only when both conditions hold can you be confident that the test accurately captures the issue and that the fix resolves it.

## Subcommands

| Command | Action | User Confirmation |
|---------|--------|-------------------|
| `/test-validation` | Run test validation from current conversation context | Not needed |
| `/test-validation <TSG-ID>` | Run test validation for a specific TSG issue | Not needed |

## Judgment Matrix

| Before Fix (old commit) | After Fix (new commit) | Verdict | Action |
|------------------------|----------------------|---------|--------|
| FAIL | PASS | VALID | Test and fix are both correct |
| PASS | PASS | BAD TEST | Test does not detect the issue — fix the test |
| FAIL | FAIL | BAD FIX | Code fix did not resolve the issue |
| PASS | FAIL | REGRESSION | Fix broke previously working behavior |

## Procedure

### Step 0: Detect Context

```
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
TSG_DIR="$PROJECT_ROOT/logs/troubleshooting"
```

If a TSG-ID argument is provided, read the corresponding TSG file from `$TSG_DIR` to understand the issue context (symptoms, cause, fix).

### Step 1: Identify Commits

Determine the two git commits to compare:

1. **After fix (new)**: Current HEAD or a user-specified commit containing the fix.
2. **Before fix (old)**: The commit immediately before the fix, or a user-specified commit.

```bash
# Default: current HEAD is the fix, parent is the before
NEW_COMMIT=$(git rev-parse HEAD)
OLD_COMMIT=$(git rev-parse HEAD~1)
```

If the user specifies commits explicitly, use those instead.
If the fix spans multiple commits, ask the user which commit range to use.

Display the commit context:
```
## Commit Context
- Before fix: {OLD_COMMIT_SHORT} — {OLD_COMMIT_MESSAGE}
- After fix:  {NEW_COMMIT_SHORT} — {NEW_COMMIT_MESSAGE}
```

### Step 2: Identify Test Files

Find the test file(s) to run. Sources (in priority order):

1. **User-specified**: If the user explicitly names a test file/path.
2. **TSG reference**: If a TSG-ID is provided, check the TSG doc for referenced test files.
3. **Changed files**: Look at the diff between the two commits for test files.
   ```bash
   git diff --name-only $OLD_COMMIT $NEW_COMMIT | grep -iE '(test|spec|_test\.|\.test\.)'
   ```
4. **Convention-based**: If the modified source file is `src/foo.py`, look for `tests/test_foo.py`, `src/foo.test.ts`, etc.

If no test files are found, inform the user and ask them to specify the test path.

### Step 3: Detect Test Runner

Detect the appropriate test runner based on the project:

| Indicator | Runner | Command |
|-----------|--------|---------|
| `pytest.ini`, `pyproject.toml [tool.pytest]`, `conftest.py` | pytest | `pytest {test_path}` |
| `package.json` with jest | jest | `npx jest {test_path}` |
| `package.json` with vitest | vitest | `npx vitest run {test_path}` |
| `package.json` with mocha | mocha | `npx mocha {test_path}` |
| `Cargo.toml` | cargo test | `cargo test {test_name}` |
| `go.mod` | go test | `go test {test_path}` |
| `build.gradle` / `pom.xml` | gradle/maven | `./gradlew test` / `mvn test` |
| `Makefile` with test target | make | `make test` |

If ambiguous, ask the user to confirm the test command.

### Step 4: Run Tests on Both Commits

Use git stash or worktree to run tests on both commits without losing current work state.

**Method: git stash approach**

```bash
# Save current state
git stash --include-untracked -m "test-validation: save state"

# 1) Test on OLD commit (before fix)
git checkout $OLD_COMMIT -- .
{TEST_COMMAND}
# Record: OLD_RESULT = PASS or FAIL

# 2) Restore to NEW commit (after fix)
git checkout $NEW_COMMIT -- .
{TEST_COMMAND}
# Record: NEW_RESULT = PASS or FAIL

# 3) Restore original state
git stash pop
```

**Alternative: git worktree approach** (preferred when possible)

```bash
# Create temporary worktrees
git worktree add /tmp/tv-old $OLD_COMMIT
git worktree add /tmp/tv-new $NEW_COMMIT

# Run tests in parallel
(cd /tmp/tv-old && {INSTALL_DEPS_IF_NEEDED} && {TEST_COMMAND})  # OLD_RESULT
(cd /tmp/tv-new && {INSTALL_DEPS_IF_NEEDED} && {TEST_COMMAND})  # NEW_RESULT

# Cleanup
git worktree remove /tmp/tv-old
git worktree remove /tmp/tv-new
```

Capture both stdout and exit code from each test run.

### Step 5: Evaluate Results

Apply the Judgment Matrix:

**VALID (FAIL -> PASS)**:
```
## Result: VALID

Test correctly detects the issue, and the code fix resolves it.

- Before fix ({OLD_COMMIT_SHORT}): FAIL
- After fix ({NEW_COMMIT_SHORT}): PASS
```

**BAD TEST (PASS -> PASS)**:
```
## Result: BAD TEST

Test does not detect the issue. It passes even on the pre-fix code.
The test must be revised to fail under the broken condition.

- Before fix ({OLD_COMMIT_SHORT}): PASS
- After fix ({NEW_COMMIT_SHORT}): PASS
```

Then automatically proceed to **Step 6: Fix Test**.

**BAD FIX (FAIL -> FAIL)**:
```
## Result: BAD FIX

The code fix did not resolve the issue. Test still fails after the fix.

- Before fix ({OLD_COMMIT_SHORT}): FAIL
- After fix ({NEW_COMMIT_SHORT}): FAIL

### Failure Output (After Fix)
{TEST_OUTPUT}
```

Report the failure details so the user can investigate the fix.

**REGRESSION (PASS -> FAIL)**:
```
## Result: REGRESSION

The code fix broke previously working behavior.

- Before fix ({OLD_COMMIT_SHORT}): PASS
- After fix ({NEW_COMMIT_SHORT}): FAIL

### Failure Output (After Fix)
{TEST_OUTPUT}
```

### Step 6: Fix Test (BAD TEST case only)

When both commits PASS, the test is not catching the issue. Analyze and fix:

1. **Read the TSG** (if available) to understand what the test should be catching.
2. **Read the diff** between OLD and NEW commits to understand what changed.
3. **Read the current test code** to understand what it actually tests.
4. **Identify the gap**: What condition does the old code violate that the test does not check?
5. **Modify the test** to assert the condition that the old code fails.
6. **Re-run Step 4** with the modified test to confirm FAIL -> PASS pattern.

If the test still does not produce FAIL -> PASS after modification, report to the user with analysis.

### Step 7: Report

Final report format:

```
## Test Validation Report

| Item | Value |
|------|-------|
| TSG | {TSG-ID or "N/A"} |
| Before commit | {OLD_COMMIT_SHORT} ({OLD_COMMIT_MESSAGE}) |
| After commit | {NEW_COMMIT_SHORT} ({NEW_COMMIT_MESSAGE}) |
| Test file | {TEST_PATH} |
| Test command | {TEST_COMMAND} |
| Before result | {FAIL/PASS} |
| After result | {FAIL/PASS} |
| Verdict | {VALID / BAD TEST / BAD FIX / REGRESSION} |

{Additional context if test was fixed or if action is needed}
```

## Key Principles

- **Commit-based comparison**: Always compare committed states. Uncommitted changes are protected via stash.
- **TSG integration**: Use issue context from TSG docs to judge whether tests validate the right conditions.
- **Automatic test repair**: On BAD TEST verdict, automatically revise the test and re-validate.
- **Language-agnostic**: Auto-detect test runner from project configuration regardless of language or framework.
- **Working directory safety**: Always restore the original working directory state after validation.
