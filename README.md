# weed-harness

Claude Code marketplace plugin — 26 specialized agents, 3 skills, 33+ SuperClaude commands, and a curated dependency bundle.

## Quick Install

```bash
# 1. Add marketplace
/plugin marketplace add weedmo/my_harness

# 2. Install all plugins
/plugin install weed-harness@weed-plugins
/plugin install oh-my-claudecode@weed-plugins
/plugin install andrej-karpathy-skills@weed-plugins
/plugin install document-skills@weed-plugins
```

Or via CLI:

```bash
claude plugin marketplace add https://github.com/weedmo/my_harness.git
claude plugin install weed-harness@weed-plugins
claude plugin install oh-my-claudecode@weed-plugins
claude plugin install andrej-karpathy-skills@weed-plugins
claude plugin install document-skills@weed-plugins
```

## What's Included

### weed-harness (this plugin)

**26 Agents** — specialized subagents for any domain:

| Category | Agents |
|----------|--------|
| Languages | `python-pro`, `rust-pro`, `cpp-pro`, `c-pro`, `sql-pro`, `shell-scripting-pro` |
| Data | `data-scientist`, `data-engineer`, `database-optimizer`, `database-admin`, `database-architect`, `nosql-specialist`, `supabase-schema-architect` |
| DevOps | `deployment-engineer`, `devops-troubleshooter`, `network-engineer` |
| ML/AI | `ml-engineer`, `mlops-engineer`, `prompt-engineer`, `mcp-expert` |
| Quality | `code-reviewer`, `test-engineer`, `debugger`, `error-detective`, `unused-code-cleaner` |
| Docs | `document-structure-analyzer` |

**3 Skills:**
- `/agent-development` — guidance for creating Claude Code agents
- `/file-organizer` — intelligent file/folder organization
- `/scout` — fast parallel reconnaissance before implementation

**33+ SuperClaude Commands** (`/sc:*`):
- `/sc:task`, `/sc:implement`, `/sc:analyze`, `/sc:test`, `/sc:build`
- `/sc:research`, `/sc:design`, `/sc:document`, `/sc:explain`
- `/sc:brainstorm`, `/sc:troubleshoot`, `/sc:cleanup`, `/sc:improve`
- `/sc:git`, `/sc:estimate`, `/sc:workflow`, `/sc:spawn`
- `/sc:index-repo`, `/sc:pm`, `/sc:recommend`, `/sc:spec-panel`, `/sc:business-panel`
- `/commit`, `/generate-ralph`

### Bundled Dependencies

| Plugin | Description |
|--------|-------------|
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | Multi-agent orchestration, 28 agents, 32 skills, intelligent model routing |
| [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) | Karpathy's coding guidelines — Think Before Coding, Simplicity First, Surgical Changes |
| [document-skills](https://github.com/anthropics/skills) | PDF, Excel, Word, PowerPoint processing |

## Configuration

After installing, enable all plugins in your `~/.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "weed-harness@weed-plugins": true,
    "oh-my-claudecode@weed-plugins": true,
    "andrej-karpathy-skills@weed-plugins": true,
    "document-skills@weed-plugins": true
  }
}
```

## Updating

```bash
/plugin marketplace update weed-plugins
/plugin update weed-harness@weed-plugins
```

## License

MIT
