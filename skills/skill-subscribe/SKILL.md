---
name: skill-subscribe
description: >-
  Install a single skill cherry-picked from an external harness/plugin GitHub
  repo into the local ~/.claude/skills, and keep it synced with upstream. Use
  this whenever the user wants to pull ONE specific skill (not a whole plugin)
  from another repo, browse/list which skills a repo contains before choosing,
  "subscribe" to a skill, track an upstream skill for
  updates, get notified when a borrowed/vendored skill changes upstream, or
  apply/refresh such an update. Also triggers on phrases like "add this skill
  from that repo", "특정 skill만 가져와", "skill 구독", "업스트림 업데이트 알림",
  "이 skill 최신으로 업데이트", and on the SessionStart notice
  "[skill-subscribe] Upstream updates available". Prefer this over manually
  copying skill folders, because it records provenance and enables update
  detection.
---

# skill-subscribe

Cherry-pick a single skill from an external GitHub repo into `~/.claude/skills/`,
remember where it came from, and detect when upstream changes it — without
pulling in the whole plugin/harness it lives in.

## How it works (the model)

A small manifest at `~/.claude/skills/.skill-subscriptions.json` is the source of
truth. Each subscribed skill records its `repo`, `subpath`, `ref`, the upstream
commit it was pinned to (`installed_sha`), and a content hash of the installed
files (so local edits can be detected). A **SessionStart hook** runs
`check.py --hook` every time a session starts; if upstream moved, it prints a
notice. **Updates are never applied automatically** — the user reviews, then you
apply with `update.py`, which backs up the old copy first.

All scripts are stdlib-only Python and shell out to `git` + `gh` (must be
authenticated: `gh auth status`). Run them from the scripts directory.

```bash
cd ~/.claude/skills/skill-subscribe/scripts
```

## Commands

### Discover (list what a repo ships)
Given just a repo, list every skill it contains (name, subpath, description) plus
any settings it carries, so the user can choose which to subscribe to. This is
the natural first step when the user points at a repo without naming a skill.

```bash
python3 discover.py <owner/repo-or-URL> [--ref REF]
python3 discover.py <owner/repo-or-URL> --json   # for tooling
```

Present the list to the user, let them pick, then run `subscribe.py` once per
chosen skill using the `path` shown. Settings (hooks/, settings.json,
.claude-plugin/) are reported for awareness but are not subscribable — copying
those is a separate, manual decision.

### Subscribe (install one skill)
The source can be `owner/repo` plus `--subpath`, or a GitHub deep link
(`/tree/<ref>/<path>`) from which the subpath and ref are inferred.

```bash
python3 subscribe.py <owner/repo> --subpath <path/to/skill> [--ref REF] [--name NAME]
python3 subscribe.py https://github.com/owner/repo/tree/main/skills/foo
```

The skill name defaults to the last path segment. After installing, make sure
the SessionStart hook is registered (idempotent):

```bash
python3 manage.py install-hook
```

### Check sibling-skill dependencies (alignment)
Cherry-picked skills often reference OTHER skills from the same repo (prose like
"use the writing-plans skill", or plugin refs like `superpowers:executing-plans`).
If those siblings aren't also subscribed, the skill may point the agent at
something that isn't installed. `subscribe.py` runs this check automatically and
warns about missing siblings; you can also run it anytime:

```bash
python3 deps.py <name>    # one skill
python3 deps.py --all     # every subscription
```

It only flags references that are *real* skills in the same repo and not yet
subscribed, then prints the exact `subscribe.py` commands to pull them. Decide
with the user whether the alignment matters before pulling more — some
references are optional "see also" links, not hard requirements.

### Check for updates
```bash
python3 check.py          # human report: ✓ up-to-date / ⟳ update / ✎ local-edits / ? error
python3 check.py --json   # machine-readable
```

### Apply an update (with backup)
```bash
python3 update.py <name>   # one skill
python3 update.py --all    # everything with changes
```
The previous copy is moved to `~/.claude/skills/.skill-subscribe-backups/<name>/`
(a hidden dir, so backups are never loaded as duplicate skills). If you edited
the local copy since install, `update.py` warns before overwriting so changes
aren't lost silently.

### List / remove
```bash
python3 manage.py list
python3 manage.py remove <name>             # also deletes the files
python3 manage.py remove <name> --keep-files
```

## When the SessionStart notice appears

If you see `[skill-subscribe] Upstream updates available for subscribed skills`,
relay it to the user and ask whether to apply (the user chose notify-then-approve,
not silent auto-update). On approval, run `update.py <name>` and report the
commit range and backup location. Don't apply without confirmation.

## Guidance for working with the user

- Before subscribing, confirm the exact `subpath` points at a real skill (it
  should contain a `SKILL.md`). `subscribe.py` warns if it doesn't.
- If the user pasted a GitHub URL, prefer passing it directly — the parser pulls
  out ref and subpath, which avoids transcription mistakes.
- Pinning to a tag or commit-ish via `--ref` makes a subscription reproducible;
  pinning to a branch tracks its tip. Mention the tradeoff if the user cares
  about stability vs. always-latest.
## Registering into weed-harness

For this user, subscribing a skill means **registering it into weed-harness**.
Subscribed skills land in `~/.claude/skills/<name>/`, which the `/harness-sync`
workflow publishes to the `~/autofree` repo (the weed-harness plugin source). So
a subscription becomes part of the harness only once it is synced. After a batch
of subscribes/updates, suggest running `/harness-sync` to register the vendored
skills (and the updated `.skill-subscriptions.json` manifest + SessionStart hook)
into weed-harness. Prefer batching — don't run a full version-bump+release per
individual subscribe.

See `references/internals.md` for the manifest schema and update-detection
details when you need to debug or extend the scripts.
