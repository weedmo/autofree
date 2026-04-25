#!/usr/bin/env bash
# verify-plan first-time setup.
# Idempotent — re-running is a no-op if everything is already configured.
#
# Checks (in order):
#   1. codex CLI is installed
#   2. codex plugin is installed (provides codex-companion.mjs)
#   3. ~/.codex/config.toml has the required defaults (model, effort, service_tier, sandbox_mode)
#   4. codex auth is active
#
# On any missing prerequisite the script prints a one-line fix and exits non-zero.
set -euo pipefail

ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }
err()  { printf '  \033[31m✗\033[0m %s\n' "$*" >&2; }
add()  { printf '  \033[36m+\033[0m %s\n' "$*"; }

echo "[verify-plan setup] Checking prerequisites…"

# 1. codex CLI
if ! command -v codex >/dev/null 2>&1; then
  err "codex CLI not found in PATH"
  err "  → Install: npm install -g @openai/codex"
  exit 1
fi
ok "codex CLI: $(codex --version 2>&1 | head -1)"

# 2. codex plugin (codex-companion.mjs)
COMPANION="$(find "${HOME}/.claude/plugins/cache/openai-codex" -type f -name codex-companion.mjs 2>/dev/null | sort -V | tail -1)"
if [[ -z "${COMPANION}" ]]; then
  err "codex plugin not installed"
  err "  → In Claude Code:  /plugin marketplace add openai/codex-plugin-cc"
  err "  → Then:            /plugin install codex@openai-codex"
  err "  → Then re-run this setup."
  exit 1
fi
ok "codex plugin: ${COMPANION}"

# 3. ~/.codex/config.toml — required defaults
CFG="${HOME}/.codex/config.toml"
if [[ ! -f "${CFG}" ]]; then
  warn "${CFG} not found; running 'codex login' will create it"
  err "  → Run: codex login"
  exit 1
fi

ensure_kv() {
  local key="$1"
  local value="$2"
  if grep -qE "^${key}[[:space:]]*=" "${CFG}"; then
    return 0
  fi
  add "Adding ${key} = ${value} to ${CFG}"
  printf '%s = %s\n' "${key}" "${value}" >> "${CFG}"
}

ensure_kv 'model' '"gpt-5.5"'
ensure_kv 'model_reasoning_effort' '"xhigh"'
ensure_kv 'service_tier' '"fast"'
ensure_kv 'sandbox_mode' '"danger-full-access"'
ok "~/.codex/config.toml has model / effort / service_tier / sandbox_mode"

# 4. codex auth — quick smoke test via codex-companion setup probe.
# Use python to parse the nested auth.loggedIn field rather than grep, so we are
# not coupled to whitespace formatting in the helper's JSON output.
SETUP_JSON="$(node "${COMPANION}" setup --json 2>/dev/null || echo '{}')"
LOGGED_IN="$(printf '%s' "${SETUP_JSON}" | python3 -c 'import json,sys
try:
    d = json.load(sys.stdin)
except Exception:
    print("false"); sys.exit(0)
print("true" if d.get("auth", {}).get("loggedIn") else "false")
' 2>/dev/null || echo false)"

if [[ "${LOGGED_IN}" == "true" ]]; then
  ok "codex auth: signed in"
else
  err "codex not signed in"
  err "  → Run: codex login   (or 'codex login --device-auth' on a headless host)"
  exit 1
fi

# 5. Remove any duplicate verify-plan Stop hook from the user's settings.json.
# Once weed-harness is installed as a plugin, hooks/hooks.json registers the Stop
# hook in plugin scope, so a user-level entry pointing at the same script would
# fire twice and inject the reminder twice.
USER_SETTINGS="${HOME}/.claude/settings.json"
if [[ -f "${USER_SETTINGS}" ]]; then
  REMOVED="$(python3 - "${USER_SETTINGS}" <<'PY'
import json, sys
path = sys.argv[1]
with open(path) as f:
    cfg = json.load(f)
hooks = cfg.get("hooks", {})
stop = hooks.get("Stop", []) or []
removed = 0
new_stop = []
for entry in stop:
    keep = []
    for h in entry.get("hooks", []):
        if "verify-plan-trigger.sh" in (h.get("command") or ""):
            removed += 1
            continue
        keep.append(h)
    if keep:
        entry["hooks"] = keep
        new_stop.append(entry)
if removed:
    if new_stop:
        hooks["Stop"] = new_stop
    elif "Stop" in hooks:
        del hooks["Stop"]
    cfg["hooks"] = hooks
    with open(path, "w") as f:
        json.dump(cfg, f, indent=2)
        f.write("\n")
print(removed)
PY
)"
  if [[ "${REMOVED:-0}" -gt 0 ]]; then
    add "Removed ${REMOVED} duplicate user-level verify-plan Stop hook(s) — plugin scope now handles it"
  fi
fi

echo
echo "[verify-plan setup] All prerequisites OK."
echo
echo "Next:"
echo "  • Invoke /verify-plan on any plan markdown file."
echo "  • Or write a plan; the bundled Stop hook will prompt Claude to run verify-plan automatically."
