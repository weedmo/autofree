# weed-harness

Claude Code plugin — productivity skills for autonomous coding, research, and development workflows.

## Quick Install

```bash
# Add marketplace
/plugin marketplace add weedmo/my_harness

# Install
/plugin install weed-harness@weed-plugins
```

Or via CLI:

```bash
claude plugin marketplace add https://github.com/weedmo/my_harness.git
claude plugin install weed-harness@weed-plugins
```

## Skills

| Skill | Description |
|-------|-------------|
| `/autocode` | Autonomous code improvement loop with optional 23-stage AutoResearchClaw pipeline |
| `/auto_research` | Autonomous ML research loop with deep-interview initialization |
| `/scout` | Fast parallel reconnaissance using Explore agents before implementation |
| `/commit` | Commit message generator |
| `/release` | Automated release workflow: version bump, tag, push, GitHub Release |
| `/pr-ready` | PR preparation workflow with test verification |
| `/tsg` | Troubleshooting guide — structured issue tracking and resolution |
| `/devlog` | Development journal — record approaches, lessons learned |
| `/test-validation` | Verify code fixes with FAIL-to-PASS pattern validation |
| `/agent-development` | Guidance for creating Claude Code agents |
| `/ecc-tools` | Skill combination advisor for document-skills workflows |
| `/a5c-ai-babysitter-isaac-sim` | NVIDIA Isaac Sim simulation and synthetic data generation |

## Configuration

Enable the plugin in `~/.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "weed-harness@weed-plugins": true
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
