<!-- OMC:START -->
<!-- OMC:VERSION:4.9.1 -->

# oh-my-claudecode - Intelligent Multi-Agent Orchestration

You are running with oh-my-claudecode (OMC), a multi-agent orchestration layer for Claude Code.
Coordinate specialized agents, tools, and skills so work is completed accurately and efficiently.

<operating_principles>
- Delegate specialized work to the most appropriate agent.
- Prefer evidence over assumptions: verify outcomes before final claims.
- Choose the lightest-weight path that preserves quality.
- Consult official docs before implementing with SDKs/frameworks/APIs.
</operating_principles>

<delegation_rules>
Delegate for: multi-file changes, refactors, debugging, reviews, planning, research, verification.
Work directly for: trivial ops, small clarifications, single commands.
Route code to `executor` (use `model=opus` for complex work). Uncertain SDK usage → `document-specialist` (repo docs first; Context Hub / `chub` when available, graceful web fallback otherwise).
</delegation_rules>

<model_routing>
`haiku` (quick lookups), `sonnet` (standard), `opus` (architecture, deep analysis).
Direct writes OK for: `~/.claude/**`, `.omc/**`, `.claude/**`, `CLAUDE.md`, `AGENTS.md`.
</model_routing>

<skills>
Invoke via `/oh-my-claudecode:<name>`. Trigger patterns auto-detect keywords.
Tier-0 workflows include `autopilot`, `ultrawork`, `ralph`, `team`, and `ralplan`.
Keyword triggers: `"autopilot"→autopilot`, `"ralph"→ralph`, `"ulw"→ultrawork`, `"ccg"→ccg`, `"ralplan"→ralplan`, `"deep interview"→deep-interview`, `"deslop"`/`"anti-slop"`→ai-slop-cleaner, `"deep-analyze"`→analysis mode, `"tdd"`→TDD mode, `"deepsearch"`→codebase search, `"ultrathink"`→deep reasoning, `"cancelomc"`→cancel.
Team orchestration is explicit via `/team`.
Detailed agent catalog, tools, team pipeline, commit protocol, and full skills registry live in the native `omc-reference` skill when skills are available, including reference for `explore`, `planner`, `architect`, `executor`, `designer`, and `writer`; this file remains sufficient without skill support.
</skills>

<verification>
Verify before claiming completion. Size appropriately: small→haiku, standard→sonnet, large/security→opus.
If verification fails, keep iterating.
</verification>

<execution_protocols>
Broad requests: explore first, then plan. 2+ independent tasks in parallel. `run_in_background` for builds/tests.
Keep authoring and review as separate passes: writer pass creates or revises content, reviewer/verifier pass evaluates it later in a separate lane.
Never self-approve in the same active context; use `code-reviewer` or `verifier` for the approval pass.
Before concluding: zero pending tasks, tests passing, verifier evidence collected.
</execution_protocols>

<hooks_and_context>
Hooks inject `<system-reminder>` tags. Key patterns: `hook success: Success` (proceed), `[MAGIC KEYWORD: ...]` (invoke skill), `The boulder never stops` (ralph/ultrawork active).
Persistence: `<remember>` (7 days), `<remember priority>` (permanent).
Kill switches: `DISABLE_OMC`, `OMC_SKIP_HOOKS` (comma-separated).
</hooks_and_context>

<cancellation>
`/oh-my-claudecode:cancel` ends execution modes. Cancel when done+verified or blocked. Don't cancel if work incomplete.
</cancellation>

<worktree_paths>
State: `.omc/state/`, `.omc/state/sessions/{sessionId}/`, `.omc/notepad.md`, `.omc/project-memory.json`, `.omc/plans/`, `.omc/research/`, `.omc/logs/`
</worktree_paths>

## Setup

Say "setup omc" or run `/oh-my-claudecode:omc-setup`.

<!-- OMC:END -->

<!-- User customizations (migrated from previous CLAUDE.md) -->

# Behavioral Guidelines

Reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

# Karpathy Coding Guidelines

When doing any code work, invoke the `karpathy-guidelines` skill and follow its principles.

# weed-harness - Global Rules

## Parallel Execution

Always run **independent tasks in parallel**. Never serialize work that has no dependencies.

| Parallel OK | Must be Sequential |
|-------------|-------------------|
| Editing different files/modules | Edit A → test A |
| Code analysis + doc analysis | Analysis → implementation plan |
| Independent module refactors | DB schema change → ORM update |

## Branch Workflow (Mandatory)

When starting development work in a git repo connected to GitHub:
1. **MUST** check the current branch with `git branch` and `git remote -v`
2. **MUST** ask the user before writing any code:
   - Which branch to base the work on (e.g., `main`, `develop`, existing feature branch)
   - What to name the new branch (or whether to work on the current branch)
3. **Do NOT** proceed with any code changes until the user confirms the branch setup
4. Create and checkout the branch only after user confirmation

## Git Commits

Do NOT include `Co-Authored-By` lines in commit messages.

## Auto-Fix After Review (Mandatory)

When reviewing code and finding issues:
1. **Fix all issues immediately** without asking the user for permission.
2. After fixing, **run relevant tests**. If tests fail, fix them too.
3. Log each fix cycle with `/devlog`. Log issues with `/devlog tsg`.
4. Never say "수정할까요?" or "진행할까요?" — just fix it.
5. The Edit/Write PostToolUse hook will trigger auto-review on your fixes.

## Scout Before Complex Tasks

For non-trivial tasks, use `/scout` to gather context before planning or implementation.
This launches parallel Explore agents that map out relevant files, code, tests, and dependencies.

## Plugin Activation Policy

Default active: **weed-harness**, **weed-cowork**, **document-skills** only.

On-demand activation (user must explicitly request):
- **oh-my-claudecode**: When orchestration is needed (autopilot, ralph, team, ultrawork, ralplan)
- **everything-claude-code**: When language-specific patterns/reviews are needed (python-review, cpp-review, deep-research, docs, context-budget)

## Sync Workflow

When the user says **"sync"**, perform the following steps:

### Scope

Sync source: `~/.claude/` (local active config)
Sync target: `~/autofree/` (this git repo)

**Sync targets (repo-owned files only):**
- `hooks/` — all `.sh` files and `hooks.json`
- `skills/` — only directories already present in repo (do NOT import skills from other plugins like gstack, omc, everything-claude-code, etc.)
- `agents/` — all files
- `CLAUDE.md` — the OMC + weed-harness section (between `<!-- OMC:START -->` and the end of file)
- `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
- `settings.json` — local active settings (statusLine, env, hooks, permissions). ALWAYS include unconditionally.
- `hud/` — all files (statusLine HUD scripts referenced by settings.json)

**Excluded:** `settings.local.json` (project-private overrides), `plugins/`, `sessions/`, `cache/`, `history.jsonl`, `projects/`, and any other runtime/state files.

### Steps

1. **Diff** — For each sync target, run `diff` between local and repo. Show a summary of changed/added/removed files. If no changes found, stop and report "Already in sync."

2. **Confirm** — Show the diff summary and proceed (do not ask for permission per auto-fix rule).

3. **Copy changes** — Update repo files from local. For new skills directories in repo that don't exist locally, keep them (repo-only files are preserved).

4. **Version bump** — Always patch bump:
   - Read current version from `.claude-plugin/plugin.json`
   - Increment patch (e.g., `2.0.1` → `2.0.2`)
   - Update all 3 locations:
     - `.claude-plugin/plugin.json` → `"version"`
     - `.claude-plugin/marketplace.json` → top-level `"version"`
     - `.claude-plugin/marketplace.json` → `plugins[0].version`

5. **Commit & Push**:
   ```
   git add -A
   git commit -m "chore: bump version to X.Y.Z"
   git tag vX.Y.Z
   git push origin main
   git push origin vX.Y.Z
   ```

6. **GitHub Release**:
   ```
   gh release create vX.Y.Z --generate-notes
   ```

7. **Verify** — Confirm tag exists and GitHub release created. Report results.
# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.
