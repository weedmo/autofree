# skill-subscribe internals

## Manifest schema

`~/.claude/skills/.skill-subscriptions.json`:

```json
{
  "version": 1,
  "subscriptions": [
    {
      "name": "pdf",
      "repo": "owner/repo",
      "subpath": "document-skills/pdf",
      "ref": "main",
      "installed_sha": "<full commit sha pinned at install/update time>",
      "install_path": "/home/<user>/.claude/skills/pdf",
      "content_hash": "<sha256 of installed file contents>",
      "subscribed_at": "ISO-8601",
      "updated_at": "ISO-8601"
    }
  ]
}
```

## Update detection

`latest_sha(repo, subpath, ref)` calls:

```
gh api "repos/{repo}/commits?sha={ref}&per_page=1&path={subpath}" --jq '.[0].sha'
```

This returns the most recent commit that touched `subpath` on `ref`. Comparing it
to `installed_sha` tells us whether the *skill specifically* changed — not just
the repo. An empty `subpath` watches the whole repo.

`content_hash` walks the installed directory in sorted order and hashes each
relative path + bytes. If the live hash differs from the stored one, the local
copy was edited after install; `update.py` surfaces this before overwriting and
`check.py` reports it as `✎ local-edits`.

## Backups

`update.py` moves the prior copy to `~/.claude/skills/.skill-subscribe-backups/<name>/`
before writing the new version. The backups root is a dot-directory so Claude
Code's skill loader (which skips hidden entries) never loads a backup as a
duplicate skill. Only the most recent backup per skill is kept.

## Fetching

`fetch_subpath` does a blobless, sparse, depth-1 clone, then
`sparse-checkout set <subpath>` and copies the result (minus `.git`) into the
install path. This avoids downloading large harness repos in full.

## Failure handling

`check.py` is wired to never break a SessionStart hook: any exception is caught,
a one-line stderr note is printed, and it exits 0. Per-subscription network/auth
failures show as `? error` rather than aborting the whole check.

## Hook registration

`manage.py install-hook` appends to `settings.json` → `hooks.SessionStart`:

```json
{ "hooks": [ { "type": "command",
              "command": "python3 ~/.claude/skills/skill-subscribe/scripts/check.py --hook",
              "timeout": 30 } ] }
```

It is idempotent (matches on the substring `skill-subscribe`). `uninstall-hook`
strips it and prunes empty groups.
```
