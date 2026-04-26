---
description: "weed-harness 사용자 환경 셋업: HUD, codex 플러그인, 추가 hooks 등록 (멱등)"
argument-hint: "[hud|codex|hooks|status|all]"
---

Run the weed-harness setup installer.

Resolve the subcommand from `$ARGUMENTS` (default: `all`):

- `hud` — install statusLine HUD only
- `codex` — install Codex plugin + custom SubagentStop hook
- `hooks` — register weed-harness extra hooks (devlog, language-rule, etc.)
- `status` — show current setup state (no writes)
- `all` (default) — run hud + codex + hooks

Execute via Bash:

```
bash "${CLAUDE_PLUGIN_ROOT}/skills/setup/install.sh" $ARGUMENTS
```

Show the script output to the user verbatim, then summarize what was installed / skipped / failed. If anything was changed, remind the user to restart Claude Code so statusLine and hooks load from the new state.
