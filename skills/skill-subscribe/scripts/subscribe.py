#!/usr/bin/env python3
"""Install a single skill from a public GitHub repo and record it for syncing.

Usage:
  subscribe.py <source> [--subpath PATH] [--ref REF] [--name NAME] [--force]

<source> may be `owner/repo` or any GitHub URL, including a `/tree/<ref>/<path>`
deep link (in which case --subpath / --ref are inferred). Examples:
  subscribe.py anthropics/skills --subpath document-skills/pdf
  subscribe.py https://github.com/owner/repo/tree/main/skills/foo
"""

import argparse
import datetime
import os

import common as c
import deps


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("source")
    ap.add_argument("--subpath", default=None)
    ap.add_argument("--ref", default=None)
    ap.add_argument("--name", default=None)
    ap.add_argument("--force", action="store_true",
                    help="overwrite an existing skill of the same name")
    args = ap.parse_args()

    repo, subpath, ref = c.parse_source(args.source, args.subpath, args.ref)
    if not ref:
        ref = c.gh_default_branch(repo)

    name = args.name or (os.path.basename(subpath) if subpath else repo.split("/")[-1])
    dest = os.path.join(c.SKILLS_DIR, name)

    data = c.load_manifest()
    if c.find_subscription(data, name) and not args.force:
        c.die(f"Already subscribed to {name!r}. Use --force to re-install, "
              f"or update.py to pull the latest version.")
    if os.path.exists(dest) and not c.find_subscription(data, name) and not args.force:
        c.die(f"{dest} already exists and is not managed by skill-subscribe. "
              f"Use --force to take it over.")

    sha = c.latest_sha(repo, subpath, ref)
    c.fetch_subpath(repo, subpath, ref, dest)

    if not os.path.exists(os.path.join(dest, "SKILL.md")):
        print(f"warning: {dest} has no SKILL.md — is {subpath!r} really a skill?")

    entry = {
        "name": name,
        "repo": repo,
        "subpath": subpath,
        "ref": ref,
        "installed_sha": sha,
        "install_path": dest,
        "content_hash": c.content_hash(dest),
        "subscribed_at": datetime.datetime.now().isoformat(timespec="seconds"),
        "updated_at": datetime.datetime.now().isoformat(timespec="seconds"),
    }
    data["subscriptions"] = [e for e in data["subscriptions"] if e["name"] != name]
    data["subscriptions"].append(entry)
    c.save_manifest(data)

    print(f"Subscribed: {name}")
    print(f"  source : {repo}@{ref}  {subpath or '(repo root)'}")
    print(f"  pinned : {sha[:12]}")
    print(f"  path   : {dest}")

    # Alignment check: does this skill lean on sibling skills not yet pulled in?
    try:
        info = deps.analyze(entry, data, {})
        if info["missing"]:
            print(f"\n  ⚠ references sibling skills not yet subscribed: "
                  f"{', '.join(info['missing'])}")
            print("    These may be needed for this skill to work as intended. "
                  "Pull them with:")
            repo_skills = c.list_repo_skills(repo, ref)
            for n in info["missing"]:
                print(f"      python3 subscribe.py {repo} --subpath {repo_skills[n]}")
    except Exception as e:
        print(f"  (dependency check skipped: {e})")


if __name__ == "__main__":
    main()
