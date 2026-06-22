#!/usr/bin/env python3
"""Check subscribed skills for upstream updates.

Usage:
  check.py            human-readable report of all subscriptions
  check.py --json     machine-readable JSON (for tooling)
  check.py --hook     silent unless updates exist; prints a SessionStart
                      notice the agent can surface. Always exits 0 so it can
                      never block a session.

For each subscription it compares the pinned `installed_sha` against the
latest upstream commit touching the skill's subpath. Network/auth failures are
treated as "unknown" rather than hard errors so a flaky connection never breaks
session startup.
"""

import argparse
import json
import sys

import common as c


def evaluate(entry):
    """Return (status, latest_sha) where status is one of
    up-to-date / update-available / local-edits / error."""
    try:
        latest = c.latest_sha(entry["repo"], entry.get("subpath", ""), entry["ref"])
    except SystemExit:
        return ("error", None)

    local_edits = (
        entry.get("content_hash")
        and c.content_hash(entry["install_path"]) != entry["content_hash"]
    )

    if latest != entry["installed_sha"]:
        status = "update-available"
    elif local_edits:
        status = "local-edits"
    else:
        status = "up-to-date"
    return (status, latest)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--hook", action="store_true")
    args = ap.parse_args()

    data = c.load_manifest()
    results = []
    for entry in data["subscriptions"]:
        status, latest = evaluate(entry)
        results.append({
            "name": entry["name"],
            "repo": entry["repo"],
            "subpath": entry.get("subpath", ""),
            "ref": entry["ref"],
            "status": status,
            "pinned": entry["installed_sha"],
            "latest": latest,
        })

    updates = [r for r in results if r["status"] == "update-available"]

    if args.json:
        print(json.dumps({"results": results}, indent=2))
        return

    if args.hook:
        # Silent when nothing changed — keep session startup quiet.
        if not updates:
            return
        print("[skill-subscribe] Upstream updates available for subscribed skills:")
        for r in updates:
            print(f"  • {r['name']} ({r['repo']}@{r['ref']}): "
                  f"{r['pinned'][:8]} → {r['latest'][:8]}")
        print("Run the skill-subscribe skill (or `update.py <name>`) to apply. "
              "Updates are NOT applied automatically.")
        return

    # Default human report.
    if not results:
        print("No subscribed skills yet. Use subscribe.py to add one.")
        return
    for r in results:
        mark = {
            "up-to-date": "✓",
            "update-available": "⟳",
            "local-edits": "✎",
            "error": "?",
        }[r["status"]]
        print(f"{mark} {r['name']:<24} {r['status']:<18} {r['repo']}@{r['ref']}")
    if updates:
        print(f"\n{len(updates)} update(s) available — run update.py <name> or --all.")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # never break a session-start hook
        print(f"[skill-subscribe] check skipped: {e}", file=sys.stderr)
        sys.exit(0)
