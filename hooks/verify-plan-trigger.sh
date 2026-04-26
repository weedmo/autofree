#!/usr/bin/env bash
# Stop hook — when Claude finishes a turn, scan for plan markdown files that
# were just written/edited but lack the verify-plan verification marker, and
# inject a system-reminder telling Claude to run the verify-plan skill.
#
# Why Stop instead of PostToolUse(Write):
# - writing-plans typically Writes a placeholder then Edits the body in place.
#   PostToolUse(Write) fires on the placeholder, before the plan is complete.
# - Stop fires after the whole turn settles — the plan file is in its final
#   state for that turn, so verification is meaningful.
# - The marker check below makes this idempotent: once verify-plan stamps
#   "> **Verified:** ..." into the plan, this hook stays silent on future
#   turns. That prevents an infinite Stop → verify → Stop loop.
set -euo pipefail

CWD="$(pwd)"
[[ -d "${CWD}" ]] || exit 0

# Find recently-modified plan files (under any /plans?/ directory, .md, mtime <5min).
# Limit scope to the current working tree to avoid scanning the whole disk.
MATCHES="$(find "${CWD}" \
  -type d \( -name node_modules -o -name .git -o -name .venv -o -name dist -o -name build \) -prune -o \
  -type f -name '*.md' -mmin -5 -print 2>/dev/null \
  | grep -iE '/plans?/[^/]+\.md$' || true)"

[[ -z "${MATCHES}" ]] && exit 0

NEEDS_VERIFY=()
while IFS= read -r f; do
  [[ -f "${f}" ]] || continue
  # Skip if the plan already carries the verification marker.
  if head -10 "${f}" 2>/dev/null | grep -qE '^> \*\*Verified:\*\*.*Codex.*Claude'; then
    continue
  fi
  # Skip files too small to be a real plan (avoid stamping every short note).
  size=$(wc -c < "${f}" 2>/dev/null || echo 0)
  [[ "${size}" -lt 500 ]] && continue
  NEEDS_VERIFY+=("${f}")
done <<< "${MATCHES}"

[[ "${#NEEDS_VERIFY[@]}" -eq 0 ]] && exit 0

{
  echo "[verify-plan trigger] One or more plan markdown files in this workspace were just written or modified and do NOT yet carry a verification marker:"
  for f in "${NEEDS_VERIFY[@]}"; do
    echo "  - ${f}"
  done
  echo ""
  echo "Invoke the verify-plan skill now on each file. Pass the absolute path as input."
  echo "Once verify-plan stamps the file, this trigger will go quiet automatically."
} >&2
exit 2
