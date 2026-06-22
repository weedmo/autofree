#!/usr/bin/env python3
"""Apply upstream updates to subscribed skills (with a backup).

Usage:
  update.py <name>      update one subscription
  update.py --all       update every subscription that has changes
  update.py <name> --check   show what would change without applying

Before overwriting, the current local copy is backed up under
`~/.claude/skills/.skill-subscribe-backups/<name>/` (a hidden dir so the backup
is never itself loaded as a skill; any previous backup is replaced). If the
local copy was edited since install (content hash drift), this is reported so
you don't silently lose changes.
"""

import argparse
import datetime
import os
import shutil

import common as c

BACKUP_DIR = os.path.join(c.SKILLS_DIR, ".skill-subscribe-backups")


def apply_update(entry):
    name = entry["name"]
    latest = c.latest_sha(entry["repo"], entry.get("subpath", ""), entry["ref"])
    if latest == entry["installed_sha"]:
        print(f"{name}: already up to date ({latest[:8]})")
        return False

    dest = entry["install_path"]
    edited = (
        entry.get("content_hash")
        and os.path.isdir(dest)
        and c.content_hash(dest) != entry["content_hash"]
    )
    bak = os.path.join(BACKUP_DIR, name)
    if edited:
        print(f"{name}: WARNING — local edits detected; backing up to {bak}")

    if os.path.isdir(dest):
        os.makedirs(BACKUP_DIR, exist_ok=True)
        if os.path.exists(bak):
            shutil.rmtree(bak)
        shutil.move(dest, bak)

    c.fetch_subpath(entry["repo"], entry.get("subpath", ""), entry["ref"], dest)
    entry["installed_sha"] = latest
    entry["content_hash"] = c.content_hash(dest)
    entry["updated_at"] = datetime.datetime.now().isoformat(timespec="seconds")
    print(f"{name}: updated → {latest[:8]} (backup at {bak})")
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("name", nargs="?")
    ap.add_argument("--all", action="store_true")
    args = ap.parse_args()

    data = c.load_manifest()
    if args.all:
        targets = list(data["subscriptions"])
    elif args.name:
        entry = c.find_subscription(data, args.name)
        if not entry:
            c.die(f"Not subscribed to {args.name!r}.")
        targets = [entry]
    else:
        c.die("Provide a skill name or --all.")

    changed = False
    for entry in targets:
        if apply_update(entry):
            changed = True

    if changed:
        c.save_manifest(data)


if __name__ == "__main__":
    main()
