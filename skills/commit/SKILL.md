---
name: commit
description: "Commit Message Generator"
---

# Commit Message Generator

Analyze all changes, split them into logical atomic commits (up to 5), and execute each commit.
Verify test coverage for new features before committing.

## Instructions

1. Run the following git commands in parallel to gather information:
   - `git status` - to see all changed files (never use -uall flag)
   - `git diff --cached` - to see staged changes
   - `git diff` - to see unstaged changes
   - `git log --oneline -10` - to see recent commit message style

2. Analyze all changes and group them into logical atomic commits (max 5):

   ### Grouping criteria
   - **By concern**: separate feature code, tests, docs, config, refactoring
   - **By module/component**: changes to different modules belong in different commits
   - **By intent**: bug fix vs. new feature vs. cleanup should not be mixed
   - A single small change = 1 commit is fine. Don't force-split for the sake of splitting.

3. For each commit group, verify before committing:

   ### Test coverage check (for feat/fix types)
   - If the change adds or modifies a function/class/endpoint, check whether corresponding test files exist
   - Search patterns: `test_*.py`, `*.test.ts`, `*.spec.ts`, `*_test.go`, etc.
   - If tests are **missing**: warn the user and ask whether to proceed or write tests first
   - If tests **exist but are not updated**: warn that existing tests may need updating
   - Pure refactors, docs, chore, and style changes skip this check

   ### Sensitive file check
   - Never stage `.env`, credentials, secrets, or API keys
   - Warn the user if any such files appear in the diff

4. Execute commits sequentially (order: infrastructure/config → core logic → tests → docs):
   - Stage only the files belonging to the current group: `git add <specific files>`
   - Determine type: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `style`, `perf`
   - Write subject line in imperative mood (max 50 chars)
   - Add body if needed (wrap at 72 chars) explaining the "why"
   - Follow the repository's existing commit message conventions
   - **Do NOT include Co-Authored-By lines**
   - Commit using HEREDOC format:
     ```
     git commit -m "$(cat <<'EOF'
     <type>(<scope>): <subject>

     <body if needed>
     EOF
     )"
     ```

5. After all commits, run `git log --oneline -<N>` to show the user what was committed.

## Output Format

For each commit, briefly explain:
- What was included and why it's grouped together
- Any test coverage warnings that were raised
- The commit message used

Present a final summary showing all commits made.
