# Mode C: Team Status (`/weed-team --status`)

1. Resolve home dir (`Bash: echo $HOME`), then Glob for `**/weed-team-*/config.json` in `{HOME_DIR}/.claude/teams`
2. If not found, print "No weed-team found. Create one with `/weed-team [task]`." and exit
3. Parse `members` from config, query TaskList, and display:

```markdown
## Weed-Team Status

**Team name:** `{team_name}`
**Core agents:** 4 (always spawned)
**On-demand agents:** {N} (spawned for current task)

### Core Agents (auto-spawned)
| # | Agent | Model | Status | Current Task |
|---|-------|-------|--------|-------------|
| 1 | debugger | sonnet | idle | - |
| 2 | test-engineer | sonnet | idle | - |
| 3 | code-reviewer | opus | idle | - |
| 4 | document-structure-analyzer | sonnet | idle | - |

### On-Demand Agents (spawned for task)
| # | Agent | Model | Status | Current Task |
|---|-------|-------|--------|-------------|
| 5 | python-pro | sonnet | busy | Writing JWT handler |
| ... | ... | ... | ... | ... |

### Registered (not yet spawned)
27 agents available in agent-reference.md. Spawned on-demand when tasks require them.

### Commands
- Message an agent: use SendMessage to `{agent-name}`
- Update team: `/weed-team --update`
- Add agent: `/weed-team --add <name>`
- Disband: `/weed-team --disband`
```

**Note:** "Core" = spawned at team creation. "On-demand" = spawned during task dispatch.
Check `members` in config.json to identify spawned agents. Agents in agent-reference.md
but not in config.json are "registered but not spawned".
