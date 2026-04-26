#!/usr/bin/env bash
# Background codex review + fix + commit after a subagent task completes.
# Triggered by SubagentStop with asyncRewake=true.
#
# Pipeline (all in background, never blocks main session):
#   1. Capture working-tree diff produced by the subagent.
#   2. Run `codex exec --full-auto` so codex can both review AND apply fixes
#      directly in the workspace (workspace-write sandbox + auto-approve).
#   3. Codex emits a verdict line (ALLOW / FIXED / BLOCKED) and a COMMIT subject.
#   4. ALLOW or FIXED  -> git add -A && commit (one commit per subagent task).
#      BLOCKED         -> no commit; ask main session to resolve.
#   5. Exit 0 silently on ALLOW; exit 2 (asyncRewake) on FIXED/BLOCKED so the
#      main session is told fixes landed or that human-side action is needed.
#
# Plugin integration:
#   The codex@openai-codex plugin ships review prompts under
#   ~/.claude/plugins/cache/openai-codex/codex/<ver>/prompts/. We borrow the
#   stop-review-gate framing (ALLOW/BLOCK verdict, grounding rules) and extend
#   it with FIXED + COMMIT contract so codex can do the fix-and-commit step
#   that the read-only companion script does not support.

set -uo pipefail

input="$(cat)"

cwd=""
if command -v jq >/dev/null 2>&1; then
  cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
fi
[ -n "$cwd" ] && cd "$cwd" 2>/dev/null

command -v codex >/dev/null 2>&1 || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Nothing to review/commit if subagent left no changes.
if [ -z "$(git status --porcelain 2>/dev/null)" ]; then
  exit 0
fi

pre_diff="$(git diff HEAD -- . 2>/dev/null)"
untracked="$(git ls-files --others --exclude-standard 2>/dev/null | tr '\n' ' ')"

max_chars=120000
diff_for_prompt="$pre_diff"
if [ "${#diff_for_prompt}" -gt "$max_chars" ]; then
  diff_for_prompt="${diff_for_prompt:0:$max_chars}

[diff truncated at ${max_chars} chars]"
fi

# Borrow framing from the codex plugin's stop-review-gate prompt when present.
plugin_prompt=""
for p in "$HOME"/.claude/plugins/cache/openai-codex/codex/*/prompts/stop-review-gate.md; do
  [ -f "$p" ] && plugin_prompt="$(cat "$p")"
done

prompt="${plugin_prompt}

You are running as a SubagentStop hook for Claude Code. The previous subagent
just finished a task. Your job is to (a) review its working-tree changes,
(b) directly fix any blocking issues you can fix safely, and (c) tell the
hook how to commit the task.

Working directory: $(pwd)
Untracked files: ${untracked:-none}

Review scope - block on these only:
  - correctness bugs, regressions
  - security issues
  - broken APIs / contracts
  - missing error handling at system boundaries
Skip stylistic nits, naming preferences, and speculative refactors.

If you find blocking issues you can fix confidently:
  - Apply minimal, surgical edits directly in this workspace.
  - Do not refactor unrelated code. Do not invent new abstractions.
  - Re-read your edits to confirm consistency with the rest of the diff.

Output contract - emit EXACTLY two lines at the end of your response,
each on its own line, nothing after them:
  Line A (verdict, pick one):
    ALLOW: <short reason - no blocking issues, no fixes applied>
    FIXED: <one-line summary of what you fixed>
    BLOCKED: <short reason a human must resolve, no fixes applied>
  Line B (commit subject, always required):
    COMMIT: <conventional-commit subject for the whole task, <= 72 chars>

Diff under review:
\`\`\`diff
${diff_for_prompt}
\`\`\`"

review="$(printf '%s' "$prompt" | codex exec --full-auto - 2>/dev/null)"
status=$?
if [ "$status" -ne 0 ] || [ -z "$review" ]; then
  exit 0
fi

verdict_line="$(printf '%s\n' "$review" | grep -m1 -E '^(ALLOW|FIXED|BLOCKED):' || true)"
commit_line="$(printf '%s\n' "$review" | grep -m1 -E '^COMMIT:' || true)"

[ -z "$verdict_line" ] && exit 0  # contract violation - skip silently

verdict="${verdict_line%%:*}"
verdict_reason="${verdict_line#*: }"
commit_subject="${commit_line#COMMIT: }"
[ -z "$commit_subject" ] && commit_subject="task: subagent changes"

do_commit() {
  local body="$1"
  git add -A 2>/dev/null
  if [ -z "$(git diff --cached --name-only 2>/dev/null)" ]; then
    return 1
  fi
  if [ -n "$body" ]; then
    git commit -qm "$commit_subject" -m "$body"
  else
    git commit -qm "$commit_subject"
  fi
}

case "$verdict" in
  ALLOW)
    if do_commit ""; then
      exit 0
    fi
    exit 0
    ;;
  FIXED)
    if do_commit "Codex post-task fix: ${verdict_reason}"; then
      printf 'Codex reviewed the subagent task, applied fixes, and committed as task unit.\n\nFix summary: %s\nCommit subject: %s\n\nRe-read affected files before continuing the next task.\n' \
        "$verdict_reason" "$commit_subject"
      exit 2
    fi
    printf 'Codex applied fixes but the commit failed (likely a pre-commit hook or git identity issue). Resolve and commit manually.\n\nFix summary: %s\n' \
      "$verdict_reason"
    exit 2
    ;;
  BLOCKED)
    printf 'Codex found a blocking issue it would not auto-fix. No commit was made. Resolve before continuing:\n\n%s\n' \
      "$verdict_reason"
    exit 2
    ;;
  *)
    exit 0
    ;;
esac
