#!/usr/bin/env bash
# omc-skill-filter.sh
# Disables specific OMC built-in skills after OMC plugin updates.
# Triggered by PostToolUse hook on Bash when omc update detected.

set -euo pipefail

OMC_CACHE_DIR="$HOME/.claude/plugins/cache/omc/oh-my-claudecode"

# Skills to DISABLE
DENYLIST=(
  ultraqa
  visual-verdict
)

# Only run on omc update context
if [ -n "${TOOL_INPUT:-}" ]; then
  case "${TOOL_INPUT}" in
    *omc*update*|*omc*upgrade*|*omc*install*|*plugin*install*oh-my-claudecode*) ;;
    *) exit 0 ;;
  esac
fi

is_denied() {
  local name="$1"
  for denied in "${DENYLIST[@]}"; do
    [ "$name" = "$denied" ] && return 0
  done
  return 1
}

disabled=0

# Process all cached versions (covers fresh installs and upgrades)
for version_dir in "$OMC_CACHE_DIR"/*/; do
  [ -d "$version_dir/skills" ] || continue

  for skill_dir in "$version_dir/skills"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")

    if is_denied "$skill_name"; then
      if [ -f "$skill_dir/SKILL.md" ]; then
        mv "$skill_dir/SKILL.md" "$skill_dir/SKILL.md.disabled"
        disabled=$((disabled + 1))
      fi
    fi
  done
done

if [ "$disabled" -gt 0 ]; then
  echo "omc-skill-filter: disabled $disabled QA skill(s)"
fi
