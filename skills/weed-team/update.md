# Mode B: Team Update (`/weed-team --update`)

Update the team when CLAUDE.md has changed or new dependencies have been added.

## Execution Flow

1. **Check team exists:** Resolve home dir (`Bash: echo $HOME`), then Glob for `**/weed-team-*/config.json` in `{HOME_DIR}/.claude/teams`. If not found:
   ```
   No weed-team found. Create one with `/weed-team [task description]`.
   ```

2. **Get current members:** Read `members` array from config → `current_agents`

3. **Re-parse CLAUDE.md:** Read `tier-algorithm.md` and run Tier 0-3 algorithm again → `new_agents`
   - Also read `agent-reference.md` to get **model** for each agent

4. **Compute diff:**
   - `to_add` = `new_agents` - `current_agents` (newly needed, with model)
   - `to_remove` = `current_agents` - `new_agents` (**removal is recommendation only**)

5. **Display results and confirm:**
   ```markdown
   ## Weed-Team Update Analysis

   ### Agents to Add ({N})
   | # | Agent | Model | Tier | Reason |
   |---|-------|-------|------|--------|
   | 1 | {agent} | sonnet | Stack | New dependency: {keyword} |
   | ... | ... | ... | ... | ... |

   ### Removal Recommendations ({M})
   | # | Agent | Model | Reason |
   |---|-------|-------|--------|
   | 1 | {agent} | sonnet | Related dependency removed |
   | ... | ... | ... | ... |

   ### No Changes
   {K} existing agents retained

   Proceed with the update?
   ```

6. **After user confirmation:**
   - Read `spawn.md` and spawn only `to_add` agents (background, with correct model from agent-reference.md)
   - If project_context available (from CLAUDE.md re-parse), use Case B prompt (context injection)
   - Send `shutdown_request` only for `to_remove` agents the user agrees to remove
   - Display final change summary
