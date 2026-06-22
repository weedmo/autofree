#!/usr/bin/env python3
"""Detect sibling-skill dependencies of subscribed skills.

A cherry-picked skill often references OTHER skills from the same repo
(e.g. "use the writing-plans skill", or `superpowers:executing-plans`). If those
siblings aren't also subscribed, the skill can send the agent looking for
something that isn't installed. This scans a skill's files for such references,
keeps only the ones that are real skills in the same repo, and reports which of
those aren't subscribed yet.

Usage:
  deps.py <name>        check one subscribed skill
  deps.py --all         check every subscription
  deps.py --json
"""

import argparse
import json
import os
import re

import common as c

# kebab-case token used as a "<name> skill" prose reference or a plugin ref
_KEBAB = r"[a-z][a-z0-9]*(?:-[a-z0-9]+)+"
PATTERNS = [
    re.compile(rf"\b(?:[a-z][a-z0-9-]*):({_KEBAB})\b"),   # superpowers:executing-plans
    re.compile(rf"skills/({_KEBAB})"),                     # skills/writing-plans
    re.compile(rf"\b({_KEBAB})\s+skill\b"),                # "writing-plans skill"
]


def referenced_names(skill_dir):
    found = set()
    for root, _dirs, files in os.walk(skill_dir):
        for fn in files:
            if not fn.endswith((".md", ".txt")):
                continue
            try:
                text = open(os.path.join(root, fn), encoding="utf-8",
                            errors="replace").read()
            except OSError:
                continue
            for pat in PATTERNS:
                found.update(pat.findall(text))
    return found


def analyze(entry, data, repo_skills_cache):
    repo, ref = entry["repo"], entry["ref"]
    key = (repo, ref)
    if key not in repo_skills_cache:
        repo_skills_cache[key] = c.list_repo_skills(repo, ref)
    repo_skills = repo_skills_cache[key]
    subscribed = {e["name"] for e in data["subscriptions"]}

    refs = referenced_names(entry["install_path"])
    # keep only references that are real sibling skills in the same repo,
    # excluding the skill's own name
    siblings = {r for r in refs if r in repo_skills and r != entry["name"]}
    missing = sorted(s for s in siblings if s not in subscribed)
    present = sorted(s for s in siblings if s in subscribed)
    # references that look like skills but live in another repo/plugin
    external = sorted(r for r in refs
                      if r not in repo_skills and re.fullmatch(_KEBAB, r)
                      and ("skill" in r or True) and r != entry["name"])
    return {
        "name": entry["name"],
        "repo": repo,
        "missing": missing,
        "present": present,
        "external": [e for e in external if e not in siblings],
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("name", nargs="?")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    data = c.load_manifest()
    if args.all:
        targets = list(data["subscriptions"])
    elif args.name:
        e = c.find_subscription(data, args.name)
        if not e:
            c.die(f"Not subscribed to {args.name!r}.")
        targets = [e]
    else:
        c.die("Provide a skill name or --all.")

    cache = {}
    results = [analyze(e, data, cache) for e in targets]

    if args.json:
        print(json.dumps({"results": results}, indent=2))
        return

    any_missing = False
    for r in results:
        print(f"{r['name']} ({r['repo']})")
        if r["missing"]:
            any_missing = True
            print(f"  ⚠ missing siblings: {', '.join(r['missing'])}")
        if r["present"]:
            print(f"  ✓ satisfied: {', '.join(r['present'])}")
        if not r["missing"] and not r["present"]:
            print("  (no sibling-skill references)")
    if any_missing:
        print("\nTo pull the missing siblings:")
        for r in results:
            if not r["missing"]:
                continue
            key = (r["repo"], next(t["ref"] for t in targets if t["name"] == r["name"]))
            repo_skills = cache[key]
            for n in r["missing"]:
                print(f"  python3 subscribe.py {r['repo']} --subpath {repo_skills[n]}")


if __name__ == "__main__":
    main()
