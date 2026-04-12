# Slack-Triggered Claude Code Bot for my-harness

**Date:** 2026-04-12  
**Status:** Approved  
**Scope:** Automate my-harness plugin modification via Slack messages

---

## Overview

A local Python daemon that listens to a Slack channel, triggers Claude Code CLI on incoming requests, and posts results back as thread replies. A pinned channel message maintains a live dashboard of the current plugin state.

---

## Architecture

### Components

| Component | Location | Purpose |
|-----------|----------|---------|
| `bot.py` | `~/my_harness_bot/` | Slack Socket Mode event handler |
| `runner.py` | `~/my_harness_bot/` | Claude CLI subprocess executor |
| `status.py` | `~/my_harness_bot/` | Plugin state scanner + Slack dashboard updater |
| `system_prompt.md` | `~/my_harness_bot/` | Context injected into every Claude invocation |
| `state.json` | `~/my_harness_bot/` | Persisted bot state (pinned message ID, last sync time) |
| `systemd service` | `/etc/systemd/system/` | Auto-start on boot, restart on failure |

### Data Flow

```
[Slack #my-harness-dev]
        |
        | User posts message (free text or /command)
        ↓
[bot.py - Socket Mode listener]
        |
        |-- Immediately ACK to Slack (prevent timeout)
        |-- Post "🔧 Starting..." to message thread
        |-- Spawn runner.py as subprocess
        ↓
[runner.py]
        |
        | Builds prompt: system_prompt.md + Slack message
        | Runs: claude --print -p "<prompt>"
        |       Working dir: ~/my_harness/
        ↓
[Claude Code CLI]
        |
        | - Modifies files in ~/my_harness/
        | - Validates changes (bash -n for hooks, etc.)
        | - git commit + push
        | - Runs sync workflow (version bump + GitHub Release)
        ↓
[runner.py receives stdout]
        |
        |-- Parse output for: changed files, commit hash, version, errors
        ↓
[bot.py]
        |
        |-- Post result summary to Slack thread
        |-- Call status.py to update pinned dashboard message
```

---

## Message Handling

### Trigger Conditions

- Bot is mentioned: `@my-harness-bot <request>`
- All messages in `#my-harness-dev` channel (configurable)

### Message Formats (both accepted)

```
# Free text
@bot hooks/language-rule.sh에 오류 처리 추가해줘

# Structured commands
@bot /fix hooks/language-rule.sh: add error handling
@bot /add skill devlog: add search command
@bot /test hooks/
@bot /status refresh
```

Parsing is intentionally minimal — Claude receives the full message and interprets intent naturally. No rigid command parser needed.

### Claude CLI Invocation

```bash
claude --print -p "$(cat system_prompt.md)\n\n## User Request\n{slack_message}"
```

Working directory is always `~/my_harness/`. Claude has full tool access to read, edit, run bash, and commit.

---

## system_prompt.md Contents

The system prompt provides Claude with:

1. **Project context**: `my_harness` is a Claude Code plugin at `~/my_harness/`
2. **Directory structure**: hooks/, skills/, agents/, CLAUDE.md, .claude-plugin/
3. **Sync workflow**: After any change, run the sync process (version bump → commit → push → GitHub Release via `gh release create`)
4. **Validation steps**: `bash -n` for shell scripts, check hooks.json consistency
5. **Output contract**: End response with a structured summary block:
   ```
   ## Summary
   - Changed: [file list]
   - Commit: [hash]
   - Version: [new version]
   - Release: [GitHub URL]
   ```

---

## Slack Dashboard (Pinned Message)

A single pinned message in `#my-harness-dev` is created on first run and updated after every successful modification.

### Format

```
📦 my-harness vX.Y.Z
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🪝 Hooks (N)
  language-rule.sh, tsg-bash-failure.sh, devlog-auto-trigger.sh,
  commit-pr-chain.sh, skill-recommend-trigger.sh, ...

🛠 Skills (N)
  devlog, scout, autocode, release, commit, pr-ready, ...

🤖 Agents
  CLAUDE-TEMPLATE.md

📋 CLAUDE.md   ✓
🧠 MEMORY.md   ✓ (N entries)

🔌 Plugins
  weed-harness vX.Y.Z
  (other active plugins from ~/.claude/plugins/)

⏱ Last updated: YYYY-MM-DD HH:MM
```

### Update Logic (`status.py`)

1. Scan `~/my_harness/hooks/` → list `.sh` files
2. Scan `~/my_harness/skills/` → list subdirectories with `SKILL.md`
3. Scan `~/my_harness/agents/` → list `.md` files
4. Read version from `~/my_harness/.claude-plugin/plugin.json`
5. Count entries in `~/.claude/projects/-home-weed/memory/MEMORY.md` (H2 sections)
6. Read installed plugins from `~/.claude/plugins/`
7. Render message string
8. If `state.json` has `pinned_message_id`: call `chat.update`
9. Else: post new message, pin it, save ID to `state.json`

---

## Systemd Service

```ini
# /etc/systemd/system/my-harness-bot.service
[Unit]
Description=my-harness Slack Bot
After=network.target

[Service]
Type=simple
User=weed
WorkingDirectory=/home/weed/my_harness_bot
ExecStart=/home/weed/miniconda3/bin/python bot.py
Restart=on-failure
RestartSec=10
EnvironmentFile=/home/weed/my_harness_bot/.env

[Install]
WantedBy=multi-user.target
```

Environment variables (`.env`):
- `SLACK_BOT_TOKEN` — Bot OAuth token (`xoxb-...`)
- `SLACK_APP_TOKEN` — App-level token for Socket Mode (`xapp-...`)
- `SLACK_CHANNEL_ID` — Target channel ID

---

## Error Handling

| Scenario | Bot Response |
|----------|-------------|
| Claude CLI exits non-zero | Post error + last N lines of stdout to thread |
| git push fails | Post error, leave local changes intact |
| Slack API rate limit | Retry with exponential backoff (3 attempts) |
| Bot crashes | systemd restarts within 10 seconds |

---

## Setup Steps (high-level)

1. Create Slack app at api.slack.com → enable Socket Mode → get tokens
2. Add bot to `#my-harness-dev` channel
3. `pip install slack-bolt`
4. Write `bot.py`, `runner.py`, `status.py`, `system_prompt.md`
5. Create `.env` with tokens
6. Register and enable systemd service
7. Test with `/status refresh` command

---

## Out of Scope

- Multi-user authorization (any message in the channel triggers Claude)
- Approval workflow before Claude executes changes
- Web UI
- Support for multiple harness repositories
