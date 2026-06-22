#!/usr/bin/env bash
# SessionStart hook: notify (do NOT auto-apply) when a newer graphifyy is on PyPI.
# graphify is distributed as the pip package `graphifyy`; the package version IS
# the skill version. We compare the pipx-installed version against PyPI's latest
# and print a one-line notice if behind. Apply with:
#   pipx upgrade graphifyy && graphify install --platform claude
#
# Must never break session startup: all failures are swallowed and we exit 0.

set +e

installed="$(pipx list 2>/dev/null | awk '/package graphifyy /{print $3; exit}' | tr -d ',')"
[ -z "$installed" ] && exit 0   # graphify not installed via pipx → nothing to check

latest="$(curl -fsS --max-time 5 https://pypi.org/pypi/graphifyy/json 2>/dev/null \
          | jq -r '.info.version' 2>/dev/null)"
[ -z "$latest" ] || [ "$latest" = "null" ] && exit 0   # offline / PyPI hiccup → stay quiet

if [ "$installed" != "$latest" ]; then
  # Only announce when latest is strictly newer (sort -V puts the larger last).
  newer="$(printf '%s\n%s\n' "$installed" "$latest" | sort -V | tail -1)"
  if [ "$newer" = "$latest" ]; then
    echo "[graphify] update available: graphifyy ${installed} → ${latest}."
    echo "  Apply with: pipx upgrade graphifyy && graphify install --platform claude"
    echo "  (not applied automatically)"
  fi
fi
exit 0
