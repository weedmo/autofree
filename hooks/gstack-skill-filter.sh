#!/usr/bin/env bash
# gstack-skill-filter.sh
# Disables gstack skills not in the allowlist after gstack updates.
# Triggered by PostToolUse hook on Skill/Bash when gstack update detected.

set -euo pipefail

GSTACK_DIR="$HOME/.claude/skills/gstack"

# Skills to KEEP active (used by weed-harness qa-flow, visual-qa, deploy-verify)
ALLOWLIST=(
  browse
  qa
  qa-only
  design-review
  design-html
  design-consultation
  design-shotgun
  plan-design-review
  investigate
  health
  review
  ship
  learn
  land-and-deploy
  canary
  benchmark
  setup-browser-cookies
  setup-deploy
  connect-chrome
)

# Check if invoked from a gstack update context
if [ -n "${TOOL_INPUT:-}" ]; then
  # PostToolUse: check if this was a gstack update command
  case "${TOOL_INPUT}" in
    *gstack-upgrade*|*gstack*update*|*gstack*upgrade*) ;;
    *) exit 0 ;;  # Not a gstack update, skip
  esac
fi

is_allowed() {
  local name="$1"
  for allowed in "${ALLOWLIST[@]}"; do
    [ "$name" = "$allowed" ] && return 0
  done
  return 1
}

disabled=0
restored=0

for skill_dir in "$GSTACK_DIR"/*/; do
  [ -d "$skill_dir" ] || continue
  skill_name=$(basename "$skill_dir")

  # Skip hidden dirs and non-skill dirs
  [[ "$skill_name" == .* ]] && continue
  [[ "$skill_name" == "node_modules" ]] && continue
  [[ "$skill_name" == "bin" ]] && continue
  [[ "$skill_name" == "lib" ]] && continue
  [[ "$skill_name" == "scripts" ]] && continue
  [[ "$skill_name" == "test" ]] && continue
  [[ "$skill_name" == "docs" ]] && continue
  [[ "$skill_name" == "extension" ]] && continue
  [[ "$skill_name" == "supabase" ]] && continue
  [[ "$skill_name" == "agents" ]] && continue

  if is_allowed "$skill_name"; then
    # Restore if previously disabled
    if [ -f "$skill_dir/SKILL.md.disabled" ] && [ ! -f "$skill_dir/SKILL.md" ]; then
      mv "$skill_dir/SKILL.md.disabled" "$skill_dir/SKILL.md"
      restored=$((restored + 1))
    fi
  else
    # Disable if active
    if [ -f "$skill_dir/SKILL.md" ]; then
      mv "$skill_dir/SKILL.md" "$skill_dir/SKILL.md.disabled"
      disabled=$((disabled + 1))
    fi
  fi
done

if [ $((disabled + restored)) -gt 0 ]; then
  echo "gstack-skill-filter: disabled=$disabled restored=$restored"
fi
