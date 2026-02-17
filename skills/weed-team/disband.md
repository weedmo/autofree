# Mode E: Disband Team (`/weed-team --disband`)

1. Resolve home dir (`Bash: echo $HOME`), then check team exists by Glob for `**/weed-team-*/config.json` in `{HOME_DIR}/.claude/teams`. If not found:
   ```
   No weed-team found.
   ```
2. Confirm via AskUserQuestion:
   ```
   question: "Disband the weed-team? All spawned agents will be terminated."
   header: "Disband"
   options:
   - label: "Disband"
     description: "Terminate all spawned agents and delete the team"
   - label: "Cancel"
     description: "Keep the team running"
   ```
3. If "Disband" selected:
   - Read `members` from config.json to get list of **spawned** agents
   - Send `shutdown_request` to all spawned members (SendMessage type: shutdown_request)
   - After all members have shut down, call `TeamDelete`
   - Display:
     ```
     Weed-team has been disbanded. {N} agents terminated.
     ```
4. If "Cancel" selected → do nothing

**Note:** Only spawned agents (in config.json members) receive shutdown_request.
Registered-but-not-spawned agents (in agent-reference.md only) are not affected.
