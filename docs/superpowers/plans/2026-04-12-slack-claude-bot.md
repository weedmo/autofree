# Slack-Triggered Claude Bot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a local Python daemon that watches a Slack channel, triggers Claude Code CLI on incoming requests, and posts results + a live plugin dashboard back to Slack.

**Architecture:** A `slack-bolt` Socket Mode bot (`bot.py`) receives Slack events and spawns `runner.py` as a subprocess to invoke `claude --print -p`. A separate `status.py` module scans `~/my_harness/` and updates a pinned Slack message with the current plugin state after each successful run.

**Tech Stack:** Python 3.10+, `slack-bolt`, `slack-sdk`, `pytest`, `miniconda3` Python at `/home/weed/miniconda3/bin/python`, systemd for service management.

---

## File Structure

| File | Responsibility |
|------|---------------|
| `~/my_harness_bot/bot.py` | Slack Socket Mode listener, event dispatch, thread replies |
| `~/my_harness_bot/runner.py` | Build Claude prompt, run CLI subprocess, parse output |
| `~/my_harness_bot/status.py` | Scan `~/my_harness/`, render dashboard, update pinned message |
| `~/my_harness_bot/system_prompt.md` | Context injected into every Claude invocation |
| `~/my_harness_bot/state.json` | Runtime state: pinned message ID, bot user ID (auto-created) |
| `~/my_harness_bot/.env` | Secrets: SLACK_BOT_TOKEN, SLACK_APP_TOKEN, SLACK_CHANNEL_ID |
| `~/my_harness_bot/.env.example` | Token template |
| `~/my_harness_bot/requirements.txt` | `slack-bolt`, `slack-sdk` |
| `~/my_harness_bot/tests/test_status.py` | Unit tests for status.py |
| `~/my_harness_bot/tests/test_runner.py` | Unit tests for runner.py |
| `/etc/systemd/system/my-harness-bot.service` | Auto-start service unit |

---

## Task 1: Project Scaffold

**Files:**
- Create: `~/my_harness_bot/requirements.txt`
- Create: `~/my_harness_bot/.env.example`
- Create: `~/my_harness_bot/tests/__init__.py`

- [ ] **Step 1: Create project directory and requirements**

```bash
mkdir -p /home/weed/my_harness_bot/tests
```

Create `~/my_harness_bot/requirements.txt`:
```
slack-bolt>=1.18.0
slack-sdk>=3.26.0
```

- [ ] **Step 2: Install dependencies**

```bash
/home/weed/miniconda3/bin/pip install slack-bolt slack-sdk pytest
```

Expected: packages install without errors.

- [ ] **Step 3: Create .env.example**

Create `~/my_harness_bot/.env.example`:
```
# Slack Bot OAuth Token (xoxb-...)
SLACK_BOT_TOKEN=xoxb-your-token-here

# Slack App-Level Token for Socket Mode (xapp-...)
SLACK_APP_TOKEN=xapp-your-token-here

# Target Slack channel ID (e.g. C0123456789)
SLACK_CHANNEL_ID=C0123456789
```

- [ ] **Step 4: Create tests/__init__.py**

Create `~/my_harness_bot/tests/__init__.py` (empty file).

- [ ] **Step 5: Commit**

```bash
cd /home/weed/my_harness_bot
git init
git add requirements.txt .env.example tests/__init__.py
git commit -m "chore: initial project scaffold"
```

---

## Task 2: system_prompt.md

**Files:**
- Create: `~/my_harness_bot/system_prompt.md`

- [ ] **Step 1: Write system_prompt.md**

Create `~/my_harness_bot/system_prompt.md`:
```markdown
# my-harness Bot Context

You are Claude Code operating on the my-harness plugin repository at `/home/weed/my_harness/`.

## Repository Structure

```
my_harness/
├── hooks/          # Shell scripts executed by Claude Code hooks
│   └── hooks.json  # Hook configuration (event → script mappings)
├── skills/         # Skill directories, each with SKILL.md
├── agents/         # Agent prompt templates (.md files)
├── CLAUDE.md       # Global instructions injected into all sessions
└── .claude-plugin/
    ├── plugin.json       # Plugin metadata and version
    └── marketplace.json  # Marketplace listing
```

## Your Task

Read the user's request carefully and:
1. Make the requested changes to the appropriate files
2. Validate shell scripts: `bash -n <file>` (must exit 0)
3. If hooks.json is modified, verify JSON is valid: `python3 -m json.tool hooks/hooks.json`
4. Run the sync workflow (see below)

## Sync Workflow (REQUIRED after every change)

After making and validating changes:

1. Read current version from `.claude-plugin/plugin.json`
2. Increment the patch version (e.g., 2.0.5 → 2.0.6)
3. Update version in THREE places:
   - `.claude-plugin/plugin.json` → `"version"` field
   - `.claude-plugin/marketplace.json` → top-level `"version"` field
   - `.claude-plugin/marketplace.json` → `plugins[0].version` field
4. Stage and commit:
   ```bash
   git add -A
   git commit -m "chore: bump version to X.Y.Z"
   ```
5. Tag and push:
   ```bash
   git tag vX.Y.Z
   git push origin main
   git push origin vX.Y.Z
   ```
6. Create GitHub release:
   ```bash
   gh release create vX.Y.Z --generate-notes
   ```

## Output Contract

You MUST end your response with this exact block (fill in actual values):

```
## Summary
- Changed: [comma-separated list of modified files, or "none"]
- Commit: [full git commit hash, or "none"]
- Version: [new version string, or "unchanged"]
- Release: [GitHub release URL, or "none"]
- Status: [success|error]
- Error: [error message if Status=error, else "none"]
```

If anything fails, set Status=error, describe what went wrong in Error, and do NOT proceed with further steps.
```

- [ ] **Step 2: Commit**

```bash
cd /home/weed/my_harness_bot
git add system_prompt.md
git commit -m "feat: add system_prompt.md for Claude context"
```

---

## Task 3: status.py (Plugin State Scanner)

**Files:**
- Create: `~/my_harness_bot/status.py`

- [ ] **Step 1: Write the failing tests first**

Create `~/my_harness_bot/tests/test_status.py`:
```python
import json
import os
import pytest
from pathlib import Path
from unittest.mock import patch, MagicMock
import sys
sys.path.insert(0, str(Path(__file__).parent.parent))

from status import scan_plugin_state, render_dashboard


def test_scan_hooks(tmp_path):
    hooks_dir = tmp_path / "hooks"
    hooks_dir.mkdir()
    (hooks_dir / "language-rule.sh").touch()
    (hooks_dir / "tsg-bash-failure.sh").touch()
    (hooks_dir / "hooks.json").touch()  # should be excluded

    state = scan_plugin_state(harness_dir=str(tmp_path))

    assert "language-rule.sh" in state["hooks"]
    assert "tsg-bash-failure.sh" in state["hooks"]
    assert "hooks.json" not in state["hooks"]
    assert len(state["hooks"]) == 2


def test_scan_skills(tmp_path):
    skills_dir = tmp_path / "skills"
    skills_dir.mkdir()
    skill_a = skills_dir / "devlog"
    skill_a.mkdir()
    (skill_a / "SKILL.md").touch()
    skill_b = skills_dir / "scout"
    skill_b.mkdir()
    (skill_b / "SKILL.md").touch()
    empty_dir = skills_dir / "empty"
    empty_dir.mkdir()  # no SKILL.md, should be excluded

    state = scan_plugin_state(harness_dir=str(tmp_path))

    assert "devlog" in state["skills"]
    assert "scout" in state["skills"]
    assert "empty" not in state["skills"]
    assert len(state["skills"]) == 2


def test_scan_agents(tmp_path):
    agents_dir = tmp_path / "agents"
    agents_dir.mkdir()
    (agents_dir / "CLAUDE-TEMPLATE.md").touch()

    state = scan_plugin_state(harness_dir=str(tmp_path))

    assert "CLAUDE-TEMPLATE.md" in state["agents"]


def test_read_version(tmp_path):
    plugin_dir = tmp_path / ".claude-plugin"
    plugin_dir.mkdir()
    (plugin_dir / "plugin.json").write_text(json.dumps({"version": "2.0.5", "name": "test"}))

    state = scan_plugin_state(harness_dir=str(tmp_path))

    assert state["version"] == "2.0.5"


def test_version_missing(tmp_path):
    state = scan_plugin_state(harness_dir=str(tmp_path))
    assert state["version"] == "unknown"


def test_render_dashboard_contains_version():
    state = {
        "version": "2.0.5",
        "hooks": ["language-rule.sh", "tsg-bash-failure.sh"],
        "skills": ["devlog", "scout"],
        "agents": ["CLAUDE-TEMPLATE.md"],
        "claude_md": True,
        "memory_entries": 3,
        "plugins": ["weed-harness v2.0.5"],
    }
    text = render_dashboard(state)
    assert "2.0.5" in text
    assert "language-rule.sh" in text
    assert "devlog" in text
    assert "CLAUDE-TEMPLATE.md" in text
    assert "3" in text


def test_render_dashboard_hook_count():
    state = {
        "version": "1.0.0",
        "hooks": ["a.sh", "b.sh", "c.sh"],
        "skills": [],
        "agents": [],
        "claude_md": False,
        "memory_entries": 0,
        "plugins": [],
    }
    text = render_dashboard(state)
    assert "3" in text
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd /home/weed/my_harness_bot
/home/weed/miniconda3/bin/pytest tests/test_status.py -v 2>&1 | head -30
```

Expected: `ImportError` or `ModuleNotFoundError` for `status`.

- [ ] **Step 3: Write status.py**

Create `~/my_harness_bot/status.py`:
```python
import json
import os
import re
from datetime import datetime
from pathlib import Path


HARNESS_DIR = os.path.expanduser("~/my_harness")
MEMORY_MD = os.path.expanduser("~/.claude/projects/-home-weed/memory/MEMORY.md")
PLUGINS_DIR = os.path.expanduser("~/.claude/plugins")
STATE_FILE = os.path.join(os.path.dirname(__file__), "state.json")


def scan_plugin_state(harness_dir: str = HARNESS_DIR) -> dict:
    """Scan my_harness directory and return current plugin state."""
    base = Path(harness_dir)

    # Hooks: .sh files only
    hooks_dir = base / "hooks"
    hooks = sorted(
        f.name for f in hooks_dir.glob("*.sh")
    ) if hooks_dir.exists() else []

    # Skills: subdirs containing SKILL.md
    skills_dir = base / "skills"
    skills = sorted(
        d.name for d in skills_dir.iterdir()
        if d.is_dir() and (d / "SKILL.md").exists()
    ) if skills_dir.exists() else []

    # Agents: .md files
    agents_dir = base / "agents"
    agents = sorted(
        f.name for f in agents_dir.glob("*.md")
    ) if agents_dir.exists() else []

    # Plugin version
    plugin_json = base / ".claude-plugin" / "plugin.json"
    version = "unknown"
    if plugin_json.exists():
        try:
            data = json.loads(plugin_json.read_text())
            version = data.get("version", "unknown")
        except json.JSONDecodeError:
            pass

    # CLAUDE.md presence
    claude_md = (base / "CLAUDE.md").exists()

    # Memory entries (count ## headings)
    memory_entries = 0
    memory_path = Path(MEMORY_MD)
    if memory_path.exists():
        text = memory_path.read_text()
        memory_entries = len(re.findall(r"^## ", text, re.MULTILINE))

    # Installed plugins
    plugins = []
    plugins_path = Path(PLUGINS_DIR)
    if plugins_path.exists():
        for d in sorted(plugins_path.iterdir()):
            if d.is_dir():
                pjson = d / "plugin.json"
                if pjson.exists():
                    try:
                        data = json.loads(pjson.read_text())
                        plugins.append(f"{data.get('name', d.name)} v{data.get('version', '?')}")
                    except json.JSONDecodeError:
                        plugins.append(d.name)

    return {
        "version": version,
        "hooks": hooks,
        "skills": skills,
        "agents": agents,
        "claude_md": claude_md,
        "memory_entries": memory_entries,
        "plugins": plugins,
    }


def render_dashboard(state: dict) -> str:
    """Render the Slack dashboard message string from state dict."""
    hooks = state["hooks"]
    skills = state["skills"]
    agents = state["agents"]
    now = datetime.now().strftime("%Y-%m-%d %H:%M")

    hooks_line = ", ".join(hooks) if hooks else "(none)"
    skills_line = ", ".join(skills) if skills else "(none)"
    agents_line = ", ".join(agents) if agents else "(none)"
    plugins_line = "\n  ".join(state["plugins"]) if state["plugins"] else "(none)"
    claude_md_mark = "✓" if state["claude_md"] else "✗"
    memory_str = f"✓ ({state['memory_entries']} entries)" if state["memory_entries"] else "✓ (empty)"

    return (
        f"📦 *my-harness v{state['version']}*\n"
        f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        f"🪝 *Hooks* ({len(hooks)})\n"
        f"  {hooks_line}\n\n"
        f"🛠 *Skills* ({len(skills)})\n"
        f"  {skills_line}\n\n"
        f"🤖 *Agents*\n"
        f"  {agents_line}\n\n"
        f"📋 CLAUDE.md   {claude_md_mark}\n"
        f"🧠 MEMORY.md   {memory_str}\n\n"
        f"🔌 *Plugins*\n"
        f"  {plugins_line}\n\n"
        f"⏱ Last updated: {now}"
    )


def load_state() -> dict:
    """Load persisted bot state from state.json."""
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE) as f:
            return json.load(f)
    return {}


def save_state(state: dict) -> None:
    """Persist bot state to state.json."""
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=2)


def update_dashboard(client) -> None:
    """Scan plugin state, render dashboard, and update pinned Slack message."""
    import os
    channel_id = os.environ["SLACK_CHANNEL_ID"]

    plugin_state = scan_plugin_state()
    text = render_dashboard(plugin_state)
    bot_state = load_state()

    if "pinned_message_id" in bot_state:
        client.chat_update(
            channel=channel_id,
            ts=bot_state["pinned_message_id"],
            text=text,
        )
    else:
        response = client.chat_postMessage(channel=channel_id, text=text)
        ts = response["ts"]
        client.pins_add(channel=channel_id, timestamp=ts)
        bot_state["pinned_message_id"] = ts
        save_state(bot_state)
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
cd /home/weed/my_harness_bot
/home/weed/miniconda3/bin/pytest tests/test_status.py -v
```

Expected: all 7 tests PASS.

- [ ] **Step 5: Commit**

```bash
cd /home/weed/my_harness_bot
git add status.py tests/test_status.py
git commit -m "feat: add status.py plugin state scanner and dashboard renderer"
```

---

## Task 4: runner.py (Claude CLI Executor)

**Files:**
- Create: `~/my_harness_bot/runner.py`
- Create: `~/my_harness_bot/tests/test_runner.py`

- [ ] **Step 1: Write the failing tests**

Create `~/my_harness_bot/tests/test_runner.py`:
```python
import pytest
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

from runner import parse_summary, build_prompt, strip_bot_mention


def test_parse_summary_success():
    output = """
Some Claude output here...

## Summary
- Changed: hooks/language-rule.sh, hooks/hooks.json
- Commit: abc1234def5678
- Version: 2.0.6
- Release: https://github.com/weed/my_harness/releases/tag/v2.0.6
- Status: success
- Error: none
"""
    result = parse_summary(output)
    assert result["status"] == "success"
    assert result["changed"] == "hooks/language-rule.sh, hooks/hooks.json"
    assert result["commit"] == "abc1234def5678"
    assert result["version"] == "2.0.6"
    assert result["release"] == "https://github.com/weed/my_harness/releases/tag/v2.0.6"
    assert result["error"] == "none"


def test_parse_summary_error():
    output = """
## Summary
- Changed: none
- Commit: none
- Version: unchanged
- Release: none
- Status: error
- Error: bash -n failed on hooks/bad.sh
"""
    result = parse_summary(output)
    assert result["status"] == "error"
    assert result["error"] == "bash -n failed on hooks/bad.sh"


def test_parse_summary_missing():
    output = "Claude output without any summary block"
    result = parse_summary(output)
    assert result["status"] == "error"
    assert "summary" in result["error"].lower()


def test_build_prompt():
    system_prompt = "You are a bot.\n## Context\nmy_harness is at ~/my_harness/"
    message = "Add error handling to language-rule.sh"
    prompt = build_prompt(system_prompt, message)
    assert "You are a bot." in prompt
    assert "Add error handling to language-rule.sh" in prompt
    assert "## User Request" in prompt


def test_strip_bot_mention():
    assert strip_bot_mention("<@U12345> fix the bug") == "fix the bug"
    assert strip_bot_mention("<@UABC123>  /fix hooks/foo.sh") == "/fix hooks/foo.sh"
    assert strip_bot_mention("no mention here") == "no mention here"
    assert strip_bot_mention("<@U1> ") == ""
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd /home/weed/my_harness_bot
/home/weed/miniconda3/bin/pytest tests/test_runner.py -v 2>&1 | head -20
```

Expected: `ImportError` for `runner`.

- [ ] **Step 3: Write runner.py**

Create `~/my_harness_bot/runner.py`:
```python
import os
import re
import subprocess
from pathlib import Path


HARNESS_DIR = os.path.expanduser("~/my_harness")
SYSTEM_PROMPT_FILE = os.path.join(os.path.dirname(__file__), "system_prompt.md")
CLAUDE_BIN = "claude"  # must be on PATH


def strip_bot_mention(text: str) -> str:
    """Remove leading <@BOTID> mention from Slack message text."""
    return re.sub(r"^<@[A-Z0-9]+>\s*", "", text).strip()


def build_prompt(system_prompt: str, message: str) -> str:
    """Combine system prompt and user message into a single Claude prompt."""
    return f"{system_prompt}\n\n## User Request\n{message}"


def parse_summary(output: str) -> dict:
    """
    Extract structured summary from Claude's output.
    Returns dict with keys: status, changed, commit, version, release, error.
    """
    match = re.search(
        r"## Summary\s*\n"
        r"- Changed:\s*(.+)\n"
        r"- Commit:\s*(.+)\n"
        r"- Version:\s*(.+)\n"
        r"- Release:\s*(.+)\n"
        r"- Status:\s*(.+)\n"
        r"- Error:\s*(.+)",
        output,
        re.MULTILINE,
    )
    if not match:
        return {
            "status": "error",
            "changed": "none",
            "commit": "none",
            "version": "unchanged",
            "release": "none",
            "error": "no summary block found in Claude output",
        }
    return {
        "changed": match.group(1).strip(),
        "commit": match.group(2).strip(),
        "version": match.group(3).strip(),
        "release": match.group(4).strip(),
        "status": match.group(5).strip(),
        "error": match.group(6).strip(),
    }


def run_claude(message: str) -> tuple[int, str]:
    """
    Run Claude CLI with the given user message.
    Returns (exit_code, stdout_output).
    """
    system_prompt = Path(SYSTEM_PROMPT_FILE).read_text()
    prompt = build_prompt(system_prompt, message)

    result = subprocess.run(
        [CLAUDE_BIN, "--print", "-p", prompt],
        cwd=HARNESS_DIR,
        capture_output=True,
        text=True,
        timeout=300,  # 5 minute timeout
    )
    output = result.stdout
    if result.returncode != 0:
        output += f"\n[stderr]: {result.stderr}"
    return result.returncode, output


def format_slack_result(summary: dict) -> str:
    """Format Claude run summary as a Slack message."""
    if summary["status"] == "success":
        lines = [
            "✅ *Done!*",
            f"📝 Changed: `{summary['changed']}`",
            f"🔖 Version: `{summary['version']}`",
            f"📦 Commit: `{summary['commit'][:8]}`",
        ]
        if summary["release"] != "none":
            lines.append(f"🚀 Release: {summary['release']}")
    else:
        lines = [
            "❌ *Failed*",
            f"Error: {summary['error']}",
        ]
    return "\n".join(lines)
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
cd /home/weed/my_harness_bot
/home/weed/miniconda3/bin/pytest tests/test_runner.py -v
```

Expected: all 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
cd /home/weed/my_harness_bot
git add runner.py tests/test_runner.py
git commit -m "feat: add runner.py for Claude CLI execution and output parsing"
```

---

## Task 5: bot.py (Slack Socket Mode Handler)

**Files:**
- Create: `~/my_harness_bot/bot.py`

- [ ] **Step 1: Write bot.py**

Create `~/my_harness_bot/bot.py`:
```python
import logging
import os
import threading
from pathlib import Path

from dotenv import load_dotenv
from slack_bolt import App
from slack_bolt.adapter.socket_mode import SocketModeHandler

from runner import run_claude, parse_summary, format_slack_result, strip_bot_mention
from status import update_dashboard, load_state, save_state

load_dotenv(Path(__file__).parent / ".env")

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger(__name__)

app = App(token=os.environ["SLACK_BOT_TOKEN"])

CHANNEL_ID = os.environ["SLACK_CHANNEL_ID"]


def handle_request(message_text: str, channel: str, thread_ts: str, client) -> None:
    """Run Claude and post result to Slack thread (called in background thread)."""
    # Strip /status refresh — handled separately
    clean_text = strip_bot_mention(message_text).strip()

    if clean_text == "/status refresh":
        update_dashboard(client)
        client.chat_postMessage(
            channel=channel,
            thread_ts=thread_ts,
            text="✅ Dashboard refreshed.",
        )
        return

    exit_code, output = run_claude(clean_text)
    summary = parse_summary(output)
    result_text = format_slack_result(summary)

    client.chat_postMessage(
        channel=channel,
        thread_ts=thread_ts,
        text=result_text,
    )

    if summary["status"] == "success":
        update_dashboard(client)


@app.event("app_mention")
def on_mention(event, client, say):
    """Handle @bot mentions anywhere."""
    channel = event["channel"]
    thread_ts = event.get("thread_ts", event["ts"])
    text = event.get("text", "")

    # Acknowledge immediately
    client.chat_postMessage(
        channel=channel,
        thread_ts=thread_ts,
        text="🔧 작업 시작...",
    )

    thread = threading.Thread(
        target=handle_request,
        args=(text, channel, thread_ts, client),
        daemon=True,
    )
    thread.start()


@app.event("message")
def on_message(event, client):
    """Handle direct messages in the target channel (non-mention messages)."""
    # Only handle messages in the configured channel, ignore bot messages and thread replies
    if event.get("channel") != CHANNEL_ID:
        return
    if event.get("subtype") in ("bot_message", "message_changed", "message_deleted"):
        return
    if event.get("thread_ts"):
        return  # Ignore thread replies to avoid loops

    text = event.get("text", "")
    if not text:
        return

    ts = event["ts"]

    client.chat_postMessage(
        channel=CHANNEL_ID,
        thread_ts=ts,
        text="🔧 작업 시작...",
    )

    thread = threading.Thread(
        target=handle_request,
        args=(text, CHANNEL_ID, ts, client),
        daemon=True,
    )
    thread.start()


def initialize_dashboard(client) -> None:
    """Create or verify the pinned dashboard message on startup."""
    state = load_state()
    if "pinned_message_id" not in state:
        log.info("No pinned dashboard found — creating one.")
        update_dashboard(client)
    else:
        log.info(f"Pinned dashboard exists at ts={state['pinned_message_id']}")


if __name__ == "__main__":
    handler = SocketModeHandler(app, os.environ["SLACK_APP_TOKEN"])
    log.info("Starting my-harness Slack bot...")

    # Initialize dashboard on startup
    from slack_sdk import WebClient
    web_client = WebClient(token=os.environ["SLACK_BOT_TOKEN"])
    initialize_dashboard(web_client)

    handler.start()
```

- [ ] **Step 2: Install python-dotenv (needed by bot.py)**

```bash
/home/weed/miniconda3/bin/pip install python-dotenv
echo "python-dotenv>=1.0.0" >> /home/weed/my_harness_bot/requirements.txt
```

- [ ] **Step 3: Verify imports work**

```bash
cd /home/weed/my_harness_bot
/home/weed/miniconda3/bin/python -c "import bot; print('imports OK')" 2>&1
```

Expected: `imports OK` (will fail if tokens missing, but import should succeed).

- [ ] **Step 4: Run full test suite**

```bash
cd /home/weed/my_harness_bot
/home/weed/miniconda3/bin/pytest tests/ -v
```

Expected: all 12 tests PASS.

- [ ] **Step 5: Commit**

```bash
cd /home/weed/my_harness_bot
git add bot.py requirements.txt
git commit -m "feat: add bot.py Slack Socket Mode handler"
```

---

## Task 6: Slack App Setup

This task is manual (requires browser). Steps:

- [ ] **Step 1: Create Slack App**

1. Go to https://api.slack.com/apps → "Create New App" → "From scratch"
2. Name: `my-harness-bot`, Workspace: your personal workspace

- [ ] **Step 2: Enable Socket Mode**

Settings → Socket Mode → Enable → Create app-level token with scope `connections:write`
→ Copy token (`xapp-...`) → save to `.env` as `SLACK_APP_TOKEN`

- [ ] **Step 3: Add Bot Scopes**

OAuth & Permissions → Bot Token Scopes → Add:
- `app_mentions:read`
- `channels:history`
- `chat:write`
- `pins:write`
- `pins:read`

- [ ] **Step 4: Enable Events**

Event Subscriptions → Enable → Subscribe to bot events:
- `app_mention`
- `message.channels`

- [ ] **Step 5: Install app to workspace**

OAuth & Permissions → "Install to Workspace" → Copy Bot Token (`xoxb-...`) → save to `.env` as `SLACK_BOT_TOKEN`

- [ ] **Step 6: Create channel and get ID**

In Slack: create channel `#my-harness-dev` → right-click → "Copy link" → the ID is the last part (e.g. `C0123456789`)
Save to `.env` as `SLACK_CHANNEL_ID`

- [ ] **Step 7: Invite bot to channel**

In `#my-harness-dev`: `/invite @my-harness-bot`

- [ ] **Step 8: Create .env file**

```bash
cp /home/weed/my_harness_bot/.env.example /home/weed/my_harness_bot/.env
# Edit .env and fill in the three token values
```

---

## Task 7: Systemd Service

**Files:**
- Create: `/etc/systemd/system/my-harness-bot.service`

- [ ] **Step 1: Write service unit file**

Create `/etc/systemd/system/my-harness-bot.service`:
```ini
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
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

- [ ] **Step 2: Enable and start service**

```bash
sudo systemctl daemon-reload
sudo systemctl enable my-harness-bot.service
sudo systemctl start my-harness-bot.service
```

- [ ] **Step 3: Verify service is running**

```bash
sudo systemctl status my-harness-bot.service
```

Expected: `Active: active (running)` and log line `Starting my-harness Slack bot...`

- [ ] **Step 4: Check logs**

```bash
journalctl -u my-harness-bot.service -n 20
```

Expected: no errors, dashboard initialization logged.

---

## Task 8: End-to-End Test

- [ ] **Step 1: Test /status refresh**

In `#my-harness-dev`, post: `@my-harness-bot /status refresh`

Expected:
- Bot replies "🔧 작업 시작..." in thread
- Bot replies "✅ Dashboard refreshed." in thread
- Pinned message appears/updates with current plugin state

- [ ] **Step 2: Test a real modification request**

In `#my-harness-dev`, post:
```
@my-harness-bot hooks/language-rule.sh 파일에 주석 한 줄 추가해줘 (테스트용)
```

Expected:
- Bot posts "🔧 작업 시작..." in thread
- After 1-3 minutes, bot posts "✅ Done!" with changed file, version, commit
- Dashboard pinned message updates with new version
- `git log` in `~/my_harness/` shows new commit
- GitHub shows new release

- [ ] **Step 3: Test error case**

In `#my-harness-dev`, post: `@my-harness-bot 존재하지 않는 파일 수정해줘 nonexistent.sh`

Expected:
- Bot posts error response with ❌ and description
- No git commit made
- Dashboard not updated

- [ ] **Step 4: Verify bot survives reboot**

```bash
sudo reboot
# After reboot:
sudo systemctl status my-harness-bot.service
```

Expected: service auto-started, `Active: active (running)`.
