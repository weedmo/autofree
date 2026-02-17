# Mode D: Manual Agent Addition (`/weed-team --add <agent-name>`)

1. Resolve home dir (`Bash: echo $HOME`), then check team exists by Glob for `**/weed-team-*/config.json` in `{HOME_DIR}/.claude/teams`. If not found:
   ```
   No weed-team found. Create one with `/weed-team [task description]`.
   ```
2. Read `agent-reference.md` and verify `<agent-name>` exists in the 27-agent list
3. If already in team members (config.json), print "Already a team member"
4. Look up the agent's **model** from agent-reference.md (opus/sonnet)
5. Read `spawn.md` and spawn the single agent with the correct model.
   - If project_context is available (from previous Phase 0), use Case B prompt
   - Otherwise use Case C prompt (minimal)
6. Display:
   ```
   Added `{agent-name}` to weed-team. (model: {model}, manual addition)
   ```
