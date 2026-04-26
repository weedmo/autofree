# Codex Plugin Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an installable Codex marketplace package for `weed-harness` and document Codex usage separately from the existing Claude plugin flow.

**Architecture:** Keep Claude packaging at the repository root and add a repo-local Codex marketplace plus a separate plugin package under `plugins/weed-harness/`. The Codex package will carry copied `skills/` and `agents/` content plus Codex-specific metadata and docs, while the root `README.md` will explain the two distribution paths separately and note that Claude hook behavior is not part of the Codex package.

**Tech Stack:** Markdown, JSON manifests, repository file packaging, Codex marketplace conventions, shell verification with `find`, `git diff`, and JSON parsing.

---

## File Structure

- Create: `.agents/plugins/marketplace.json`
- Create: `plugins/weed-harness/.codex-plugin/plugin.json`
- Create: `plugins/weed-harness/AGENTS.md`
- Create: `plugins/weed-harness/README.md`
- Create: `plugins/weed-harness/skills/**` by copying from `skills/**`
- Create: `plugins/weed-harness/agents/**` by copying from `agents/**`
- Modify: `README.md`

### Task 1: Add Codex marketplace metadata

**Files:**
- Create: `.agents/plugins/marketplace.json`

- [ ] **Step 1: Write the marketplace file**

```json
{
  "name": "weedmo-autofree",
  "interface": {
    "displayName": "weedmo Codex Plugins"
  },
  "plugins": [
    {
      "name": "weed-harness",
      "source": {
        "source": "local",
        "path": "./plugins/weed-harness"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Coding"
    }
  ]
}
```

- [ ] **Step 2: Run JSON validation**

Run: `python3 -m json.tool .agents/plugins/marketplace.json >/dev/null`
Expected: command exits successfully with no output

- [ ] **Step 3: Commit**

```bash
git add .agents/plugins/marketplace.json
git commit -m "feat: add Codex marketplace metadata"
```

### Task 2: Create the Codex plugin manifest and package docs

**Files:**
- Create: `plugins/weed-harness/.codex-plugin/plugin.json`
- Create: `plugins/weed-harness/AGENTS.md`
- Create: `plugins/weed-harness/README.md`

- [ ] **Step 1: Write the plugin manifest**

```json
{
  "name": "weed-harness",
  "version": "2.1.3",
  "description": "Codex packaging for weed-harness productivity skills and coding workflows.",
  "author": {
    "name": "weedmo",
    "url": "https://github.com/weedmo"
  },
  "homepage": "https://github.com/weedmo/autofree",
  "repository": "https://github.com/weedmo/autofree",
  "license": "MIT",
  "keywords": [
    "codex",
    "skills",
    "coding",
    "workflow"
  ],
  "skills": "./skills/",
  "interface": {
    "displayName": "weed-harness",
    "shortDescription": "Reusable coding and productivity workflows for Codex",
    "longDescription": "Install weed-harness in Codex to get packaged skills and agent guidance for autonomous coding, research, QA, and release workflows.",
    "developerName": "weedmo",
    "category": "Coding",
    "capabilities": [
      "Interactive",
      "Read",
      "Write"
    ],
    "defaultPrompt": [
      "Audit this repo and suggest the next coding task.",
      "Use the packaged workflow skills to plan this change.",
      "Review my diff and point out the main risks."
    ],
    "brandColor": "#2563EB",
    "screenshots": []
  }
}
```

- [ ] **Step 2: Write package-local docs**

`plugins/weed-harness/AGENTS.md` should state that this package exposes copied `skills/` and `agents/` content for Codex, and that some workflows remain Claude-optimized because hook behavior and slash commands are not part of Codex packaging.

`plugins/weed-harness/README.md` should explain:
- What the package contains
- The copied-content strategy
- The known Claude-specific limitations
- Where the root README explains installation

- [ ] **Step 3: Run JSON validation**

Run: `python3 -m json.tool plugins/weed-harness/.codex-plugin/plugin.json >/dev/null`
Expected: command exits successfully with no output

- [ ] **Step 4: Commit**

```bash
git add plugins/weed-harness/.codex-plugin/plugin.json plugins/weed-harness/AGENTS.md plugins/weed-harness/README.md
git commit -m "feat: add Codex plugin manifest and docs"
```

### Task 3: Copy skills and agents into the Codex package

**Files:**
- Create: `plugins/weed-harness/skills/**`
- Create: `plugins/weed-harness/agents/**`

- [ ] **Step 1: Copy the existing skill tree into the package**

Run: `mkdir -p plugins/weed-harness && cp -R skills plugins/weed-harness/`
Expected: `plugins/weed-harness/skills/` exists and includes the same top-level skill directories and `SKILL.md` files as the root `skills/`

- [ ] **Step 2: Copy the existing agent tree into the package**

Run: `cp -R agents plugins/weed-harness/`
Expected: `plugins/weed-harness/agents/` exists and includes the same files as the root `agents/`

- [ ] **Step 3: Verify copied content**

Run: `find plugins/weed-harness -maxdepth 2 \\( -path 'plugins/weed-harness/skills' -o -path 'plugins/weed-harness/agents' \\) -print`
Expected:

```text
plugins/weed-harness/skills
plugins/weed-harness/agents
```

- [ ] **Step 4: Commit**

```bash
git add plugins/weed-harness/skills plugins/weed-harness/agents
git commit -m "feat: package skills and agents for Codex"
```

### Task 4: Update the root README for Claude and Codex

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Keep the Claude install flow first**

Retain the current Claude-oriented quick install and update commands near the top of `README.md`.

- [ ] **Step 2: Add a dedicated Codex section**

Add a section with content equivalent to:

```md
## Codex

Add the marketplace:

```bash
codex marketplace add weedmo/autofree
```

After adding the marketplace, install or enable `weed-harness` from Codex's plugin UI. The Codex package lives under `plugins/weed-harness/` and contains copied `skills/` and `agents/` content so it can be installed independently of the Claude plugin layout.

Current limitation: Claude-specific hook automation and slash-command behavior are not part of the Codex package.
```

- [ ] **Step 3: Adjust wording in the intro**

Update the opening paragraph so the repository is described as a Claude plugin plus Codex package, rather than Claude-only.

- [ ] **Step 4: Review README rendering**

Run: `sed -n '1,220p' README.md`
Expected: Claude and Codex sections are clearly separated and the Codex instructions do not claim an unverified CLI install command

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "docs: add Codex installation guide"
```

### Task 5: Final verification

**Files:**
- Verify: `.agents/plugins/marketplace.json`
- Verify: `plugins/weed-harness/.codex-plugin/plugin.json`
- Verify: `plugins/weed-harness/**`
- Verify: `README.md`

- [ ] **Step 1: Validate both JSON manifests**

Run: `python3 -m json.tool .agents/plugins/marketplace.json >/dev/null && python3 -m json.tool plugins/weed-harness/.codex-plugin/plugin.json >/dev/null`
Expected: command exits successfully with no output

- [ ] **Step 2: Verify the packaged tree**

Run: `find plugins/weed-harness -maxdepth 3 | sort | sed -n '1,120p'`
Expected: output includes `.codex-plugin/plugin.json`, `AGENTS.md`, `README.md`, `skills/`, and `agents/`

- [ ] **Step 3: Review the diff surface**

Run: `git diff --stat HEAD~4..HEAD`
Expected: diff only covers the Codex marketplace file, Codex plugin package, and README changes

- [ ] **Step 4: Final commit if verification required changes**

```bash
git add .agents/plugins/marketplace.json plugins/weed-harness README.md
git commit -m "chore: finalize Codex plugin support"
```
