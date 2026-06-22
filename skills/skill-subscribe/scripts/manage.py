#!/usr/bin/env python3
"""List or remove subscriptions, and register the SessionStart hook.

Usage:
  manage.py list                 show all subscriptions (from the manifest)
  manage.py remove <name> [--keep-files]
  manage.py install-hook         add the SessionStart check hook to settings.json
  manage.py uninstall-hook       remove it
"""

import argparse
import json
import os
import shutil

import common as c

SETTINGS = os.path.join(c.HOME, ".claude", "settings.json")
HOOK_CMD = "python3 ~/.claude/skills/skill-subscribe/scripts/check.py --hook"


def cmd_list(_):
    data = c.load_manifest()
    if not data["subscriptions"]:
        print("No subscriptions.")
        return
    for e in data["subscriptions"]:
        print(f"{e['name']}")
        print(f"  {e['repo']}@{e['ref']}  {e.get('subpath') or '(root)'}")
        print(f"  pinned {e['installed_sha'][:12]}  updated {e.get('updated_at','?')}")


def cmd_remove(args):
    data = c.load_manifest()
    entry = c.find_subscription(data, args.name)
    if not entry:
        c.die(f"Not subscribed to {args.name!r}.")
    data["subscriptions"] = [e for e in data["subscriptions"] if e["name"] != args.name]
    c.save_manifest(data)
    if not args.keep_files and os.path.isdir(entry["install_path"]):
        shutil.rmtree(entry["install_path"])
        print(f"Removed {args.name} and deleted {entry['install_path']}")
    else:
        print(f"Removed {args.name} from manifest (files kept at {entry['install_path']})")


def _load_settings():
    if not os.path.exists(SETTINGS):
        return {}
    with open(SETTINGS) as f:
        return json.load(f)


def _save_settings(s):
    with open(SETTINGS, "w") as f:
        json.dump(s, f, indent=2)
        f.write("\n")


def cmd_install_hook(_):
    s = _load_settings()
    hooks = s.setdefault("hooks", {})
    sessions = hooks.setdefault("SessionStart", [])
    for group in sessions:
        for h in group.get("hooks", []):
            if "skill-subscribe" in h.get("command", ""):
                print("SessionStart hook already installed.")
                return
    sessions.append({
        "hooks": [{"type": "command", "command": HOOK_CMD, "timeout": 30}]
    })
    _save_settings(s)
    print("Installed SessionStart hook in settings.json.")


def cmd_uninstall_hook(_):
    s = _load_settings()
    sessions = s.get("hooks", {}).get("SessionStart", [])
    for group in sessions:
        group["hooks"] = [h for h in group.get("hooks", [])
                          if "skill-subscribe" not in h.get("command", "")]
    s.setdefault("hooks", {})["SessionStart"] = [g for g in sessions if g.get("hooks")]
    _save_settings(s)
    print("Removed SessionStart hook from settings.json.")


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("list").set_defaults(func=cmd_list)
    rm = sub.add_parser("remove")
    rm.add_argument("name")
    rm.add_argument("--keep-files", action="store_true")
    rm.set_defaults(func=cmd_remove)
    sub.add_parser("install-hook").set_defaults(func=cmd_install_hook)
    sub.add_parser("uninstall-hook").set_defaults(func=cmd_uninstall_hook)
    args = ap.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
