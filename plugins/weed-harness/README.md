# weed-harness for Codex

This directory is the Codex plugin package for `weed-harness`.

## Contents

- `.codex-plugin/plugin.json` for Codex plugin metadata
- `skills/` copied from the repository root so the package is independently installable
- `agents/` copied from the repository root for packaged agent guidance
- `AGENTS.md` with Codex-specific notes for this package

## Scope

The package is intended to make the repository's workflow library installable in Codex without depending on the root Claude plugin layout.

Some packaged skills still describe Claude-specific behavior such as hooks, slash commands, or `~/.claude` paths. Those references are preserved as-is and should be treated as Claude-oriented guidance unless a Codex equivalent is available.

Root installation instructions live in the repository `README.md`.
