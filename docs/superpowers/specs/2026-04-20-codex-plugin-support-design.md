# Codex Plugin Support Design

**Date:** 2026-04-20

## Goal

Add first-class Codex packaging to `autofree` without disturbing the existing Claude plugin layout, and document both installation paths clearly in the root README.

## Approved Constraints

- Keep the current Claude plugin at the repository root as-is.
- Add Codex support as a separate package under `plugins/weed-harness/`.
- Document Codex in a separate README section instead of mixing it into the Claude quickstart.
- Make the Codex package independently installable by copying the needed assets into the plugin directory rather than referencing root files.

## Current State

- Claude distribution already exists through `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.
- The repository README only explains Claude installation and updates.
- The reusable content currently lives at the repository root in `skills/`, `agents/`, `hooks/`, and `CLAUDE.md`.
- Several skills mention Claude-specific concepts such as hooks, slash commands, or `~/.claude` paths, so Codex support should be framed as packaged availability of the workflows, not feature parity with Claude runtime behavior.

## Recommended Approach

### 1. Add a separate Codex marketplace surface

Create a repo-root Codex marketplace file at `.agents/plugins/marketplace.json` with one entry:

- `name`: `weed-harness`
- `source.path`: `./plugins/weed-harness`
- `policy.installation`: `AVAILABLE`
- `policy.authentication`: `ON_INSTALL`
- `category`: `Coding`

This matches Codex's marketplace layout conventions without interfering with the Claude marketplace files.

### 2. Create an independently installable Codex plugin package

Create `plugins/weed-harness/` with:

- `.codex-plugin/plugin.json`
- `skills/` copied from the root `skills/` tree
- `agents/` copied from the root `agents/` tree
- `AGENTS.md` containing Codex-specific top-level guidance for this package
- `README.md` describing the Codex package contents and caveats

Do not include `hooks/` in the Codex package for this first pass. Codex plugin manifests can expose hooks, but current Codex behavior is not hook-centric and the repo's hook scripts are Claude-oriented. Shipping them would suggest support that the package does not actually provide.

### 3. Keep metadata aligned with the current release

Set the Codex plugin manifest version to `2.1.3` so the new Codex package aligns with the already-bumped Claude metadata.

Populate Codex interface metadata with:

- Display name based on `weed-harness`
- A short and long description focused on coding workflows and reusable skills
- `category: "Coding"`
- Conservative capabilities such as `Interactive`, `Read`, and `Write`
- Up to three short starter prompts

### 4. Document Codex separately in the root README

Update `README.md` so it keeps Claude first, then adds a dedicated Codex section that explains:

- Codex marketplace addition via `codex marketplace add`
- Where the plugin appears after the marketplace is added
- That the Codex package ships copied skills and agents under `plugins/weed-harness/`
- That Claude-only hook automation is not part of the Codex package

The README should avoid claiming a CLI `install` subcommand unless it is confirmed by the installed Codex CLI or official OpenAI docs. As of this design, `codex marketplace add` is confirmed locally, while a separate CLI install command is not.

### 5. Treat this as packaging support, not a full skill port

This change should not rewrite every skill for Codex semantics. The objective is:

- Codex can discover and install a proper plugin package from this repo
- Codex users receive the packaged skills and agents
- Documentation clearly states the current portability boundary

This keeps scope tight and avoids a misleading partial rewrite of skill behavior.

## File Plan

### New files

- `.agents/plugins/marketplace.json`
- `plugins/weed-harness/.codex-plugin/plugin.json`
- `plugins/weed-harness/AGENTS.md`
- `plugins/weed-harness/README.md`
- `plugins/weed-harness/skills/**`
- `plugins/weed-harness/agents/**`

### Modified files

- `README.md`

## Verification Plan

- Validate all new JSON files by parsing them with `jq` or Python's JSON loader.
- Confirm the new Codex package tree contains the expected copied `skills/` and `agents/` content.
- Re-read the final `README.md` to ensure Claude and Codex installation paths are separated cleanly.
- Run `git diff --stat` and inspect the changed files for accidental scope creep.

## Risks and Tradeoffs

### Content drift

Copying `skills/` and `agents/` into `plugins/weed-harness/` creates duplication. This is intentional because the user requested an independently installable Codex package. The tradeoff is manual synchronization until a later automation pass exists.

### Runtime mismatch

Some skill text references Claude-specific runtime features. The Codex package should not hide that fact. The README and plugin-local docs should explicitly position this as a packaged workflow library for Codex, with some workflows remaining Claude-optimized.

### Maintenance scope

This design does not extend the repo's existing sync or release automation to manage the new Codex package. That can be a follow-up if the packaging proves useful.

## Out of Scope

- Rewriting all skills to be fully Codex-native
- Porting Claude hook scripts to Codex behavior
- Adding new release automation for the Codex package
- Changing the existing Claude plugin structure
