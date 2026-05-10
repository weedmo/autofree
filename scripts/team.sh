#!/usr/bin/env bash
# team.sh - tmux-based agent team orchestrator
# Subcommands: init, attach, dispatch, sub, ask, log, status

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SESSION="${TEAM_SESSION:-team-$(basename "$ROOT")}"
TEAM_DIR="$ROOT/.team"
BUS_LOG="$TEAM_DIR/bus.log"

mkdir -p "$TEAM_DIR/tasks" "$TEAM_DIR/cache"
touch "$BUS_LOG"

log_event() {
  echo "[$(date +%Y-%m-%dT%H:%M:%S)] $*" >> "$BUS_LOG"
}

cmd_init() {
  if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "session $SESSION already exists; attaching"
    cmd_attach
    return
  fi
  tmux new-session -d -s "$SESSION" -c "$ROOT" -n main
  tmux send-keys -t "$SESSION:main.0" "claude" C-m
  tmux split-window -h -t "$SESSION:main" -c "$ROOT"
  tmux send-keys -t "$SESSION:main.1" "codex" C-m
  tmux split-window -v -t "$SESSION:main.1" -c "$ROOT"
  tmux send-keys -t "$SESSION:main.2" "gemini" C-m
  tmux split-window -v -t "$SESSION:main.0" -c "$ROOT"
  tmux send-keys -t "$SESSION:main.3" "tail -F $BUS_LOG" C-m
  tmux select-pane -t "$SESSION:main.0"
  log_event "init session=$SESSION root=$ROOT"
  cmd_attach
}

cmd_attach() {
  if [[ -n "${TMUX:-}" ]]; then
    tmux switch-client -t "$SESSION"
  else
    tmux attach -t "$SESSION"
  fi
}

# dispatch <agent> <feature>
cmd_dispatch() {
  local agent="$1" feature="$2"
  local task_dir="$TEAM_DIR/tasks/$feature"
  [[ -d "$task_dir" ]] || { echo "ERROR: $task_dir not found" >&2; exit 1; }

  local pane
  case "$agent" in
    claude) pane="$SESSION:main.0" ;;
    codex)  pane="$SESSION:main.1" ;;
    gemini) pane="$SESSION:main.2" ;;
    *) echo "ERROR: unknown agent $agent" >&2; exit 1 ;;
  esac

  local prompt
  prompt="Read $task_dir/goal.md, $task_dir/tools.md, and $task_dir/plan.md. Execute the goal per its exit criteria. Use the sub-team API in tools.md when helpful. Write final summary to $task_dir/result.md. Run: team.sh log \"DONE $feature\" when complete. If blocked, run: team.sh log \"STUCK $feature <reason>\" and wait for human intervention."

  tmux send-keys -t "$pane" "$prompt" C-m
  log_event "dispatch agent=$agent feature=$feature"
}

# sub <name> <agent> "<prompt>"  - workers spawn helpers
cmd_sub() {
  local name="$1" agent="$2" prompt="$3"
  local sub_pane
  sub_pane=$(tmux split-window -t "$SESSION:main" -c "$ROOT" -P -F "#{pane_id}" \
    "echo '--- sub: $name ($agent) ---'; echo \"$prompt\" | $agent; echo '--- sub done ---'; read -p 'press enter to close > '")
  log_event "sub spawn name=$name agent=$agent pane=$sub_pane"
}

# ask <agent> "<query>"  - synchronous one-shot
cmd_ask() {
  local agent="$1" query="$2"
  local out="$TEAM_DIR/cache/$(date +%s)-$agent.md"
  echo "$query" | "$agent" --print > "$out" 2>&1 || true
  log_event "ask agent=$agent out=$out"
  cat "$out"
}

cmd_log() {
  log_event "$*"
}

cmd_status() {
  echo "=== Team Status ==="
  echo "Session: $SESSION"
  echo "Root:    $ROOT"
  echo
  echo "=== Active panes ==="
  tmux list-panes -t "$SESSION:main" -F "#{pane_index}: #{pane_current_command}" 2>/dev/null || echo "(no session)"
  echo
  echo "=== Tasks ==="
  for d in "$TEAM_DIR"/tasks/*/; do
    [[ -d "$d" ]] || continue
    local f state
    f="$(basename "$d")"
    state="planning"
    [[ -f "$d/result.md" ]] && state="impl-done"
    if [[ -f "$d/.refine-verdict.json" ]]; then
      grep -q '"final": *"APPROVE"' "$d/.refine-verdict.json" 2>/dev/null && state="plan-locked"
    fi
    echo "  $f ($state)"
  done
  echo
  echo "=== Recent bus log (last 10) ==="
  tail -10 "$BUS_LOG" 2>/dev/null
}

case "${1:-help}" in
  init)     cmd_init ;;
  attach)   cmd_attach ;;
  dispatch) shift; cmd_dispatch "$@" ;;
  sub)      shift; cmd_sub "$@" ;;
  ask)      shift; cmd_ask "$@" ;;
  log)      shift; cmd_log "$@" ;;
  status)   cmd_status ;;
  *)
    cat <<'EOF'
Usage: team.sh <subcommand> [args]

  init                          Bootstrap tmux session with claude|codex|gemini panes
  attach                        Attach to existing session
  dispatch <agent> <feature>    Send goal package to agent pane (claude|codex|gemini)
  sub <name> <agent> "<prompt>" Spawn helper sub-pane (workers call this)
  ask <agent> "<query>"         Synchronous one-shot query, returns markdown
  log "<message>"               Append to bus.log
  status                        Show pane + task state

Env: TEAM_SESSION (default: team-<repo-or-cwd-name>)
EOF
    ;;
esac
