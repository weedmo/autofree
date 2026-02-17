# Commit Message Generator

Generate a commit message for staged and unstaged changes without actually committing.
Runs pre-commit hooks to ensure code quality before generating the message.

## Instructions

1. Run the following git commands in parallel to gather information:
   - `git status` - to see all changed files (never use -uall flag)
   - `git diff --cached` - to see staged changes
   - `git diff` - to see unstaged changes
   - `git log --oneline -10` - to see recent commit message style

2. Stage all changes if needed:
   - If there are unstaged changes that should be included, stage them with `git add`
   - Ask user if unsure which files to stage

3. Run pre-commit hooks:
   - Execute `pre-commit run --all-files` (or `pre-commit run` for staged files only)
   - If pre-commit fails, fix the issues automatically if possible
   - Re-run pre-commit until all hooks pass
   - If auto-fix is not possible, report the issues to the user and stop

4. Analyze all changes and draft a commit message:
   - Determine the type: feat, fix, refactor, docs, test, chore, style, perf
   - Identify the scope if applicable (module or component name)
   - Write a concise subject line (max 50 chars) in imperative mood
   - Add body if needed (wrap at 72 chars) explaining the "why"
   - Follow the repository's existing commit message conventions

5. Output the commit message in a copyable format:
   ```
   <type>(<scope>): <subject>

   <body if needed>

   Co-Authored-By: Claude <noreply@anthropic.com>
   ```

6. **DO NOT run `git commit`** - only generate the message for the user to review and use.

## Output Format

Present the commit message clearly so the user can copy it. Also provide a brief summary of what changed.
