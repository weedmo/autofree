#!/usr/bin/env bash
# pipeline.sh - feature pipeline orchestrator
# Phases: split | goal | impl | review

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TEAM_DIR="$ROOT/.team"
TEMPLATES="$HOME/.claude/skills/team-templates"

usage() {
  cat <<'EOF'
Usage: pipeline.sh <phase> [args]

  split                Read .team/plan/master.md, create worktrees + task dirs
  goal <feature>       Generate goal.md from plan.md (Claude --print)
  impl <feature>       Dispatch goal package to codex pane
  review <feature>     Review codex result, apply refactor, create PR (Claude --print)

EOF
}

cmd_split() {
  local master="$TEAM_DIR/plan/master.md"
  [[ -f "$master" ]] || { echo "ERROR: $master not found. Run /grill-me first to produce master plan." >&2; exit 1; }

  local features
  features=$(grep -E '^## feat-[a-zA-Z0-9_-]+' "$master" | sed 's/^## //' | awk '{print $1}')
  [[ -n "$features" ]] || { echo "ERROR: no '## feat-*' headings in $master" >&2; exit 1; }

  local in_git=0
  [[ -d "$ROOT/.git" ]] && in_git=1

  while read -r f; do
    [[ -z "$f" ]] && continue
    local task_dir="$TEAM_DIR/tasks/$f"
    local wt_dir="$ROOT/.worktree/$f"

    mkdir -p "$task_dir"
    for t in prd plan goal tools; do
      [[ -f "$task_dir/$t.md" ]] || cp "$TEMPLATES/$t.md" "$task_dir/$t.md"
    done

    if [[ $in_git -eq 1 ]] && [[ ! -d "$wt_dir" ]]; then
      git -C "$ROOT" worktree add "$wt_dir" -b "$f" 2>/dev/null \
        || git -C "$ROOT" worktree add "$wt_dir" "$f" \
        || echo "  (skipped worktree for $f - branch may already exist elsewhere)"
    fi

    if [[ $in_git -eq 1 ]]; then
      echo "OK  $f  -> $task_dir + $wt_dir"
    else
      echo "OK  $f  -> $task_dir  (no git, skipped worktree)"
    fi
  done <<< "$features"
}

cmd_goal() {
  local feature="$1"
  local task_dir="$TEAM_DIR/tasks/$feature"
  [[ -f "$task_dir/plan.md" ]] || { echo "ERROR: $task_dir/plan.md missing" >&2; exit 1; }

  local prompt
  prompt="Read $task_dir/plan.md, $task_dir/prd.md, and $task_dir/tools.md. Produce a goal.md with these sections:
- Goal (single sentence)
- Why (one paragraph)
- Exit Criteria (testable bullet list with checkboxes)
- Constraints (bullet list)
- Allowed Sub-team Tools (verbatim copy of $task_dir/tools.md content)

Be concise. goal.md is the single source of truth Codex will execute against. Output only the markdown for goal.md - no preamble."

  claude --print "$prompt" > "$task_dir/goal.md"
  echo "OK  goal.md written for $feature ($(wc -l < "$task_dir/goal.md") lines)"
}

cmd_impl() {
  local feature="$1"
  "$HOME/.claude/scripts/team.sh" dispatch codex "$feature"
}

cmd_review() {
  local feature="$1"
  local task_dir="$TEAM_DIR/tasks/$feature"
  local wt_dir="$ROOT/.worktree/$feature"

  [[ -f "$task_dir/result.md" ]] || { echo "ERROR: $task_dir/result.md missing - codex not done yet" >&2; exit 1; }
  [[ -d "$wt_dir" ]] || { echo "ERROR: worktree $wt_dir missing" >&2; exit 1; }

  local prompt
  prompt="You are reviewing the implementation in $wt_dir.
1. Read $task_dir/result.md and $task_dir/goal.md.
2. cd $wt_dir && run 'git diff main...HEAD' (or whatever the base branch is).
3. Verify each Exit Criterion in goal.md is satisfied. List PASS/FAIL per criterion.
4. Apply small surgical refactors only if necessary. Do NOT scope-creep.
5. Invoke /review skill for pre-landing review.
6. If review passes, invoke /ship to create PR. Do NOT auto-merge.
Report final PR URL or any blockers."

  ( cd "$wt_dir" && claude --print "$prompt" )
}

case "${1:-help}" in
  split)  cmd_split ;;
  goal)   shift; cmd_goal "$@" ;;
  impl)   shift; cmd_impl "$@" ;;
  review) shift; cmd_review "$@" ;;
  *)      usage ;;
esac
