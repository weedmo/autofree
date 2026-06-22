#!/usr/bin/env python3
"""Discover the skills (and settings) a GitHub repo ships, so the user can pick.

Usage:
  discover.py <source> [--ref REF] [--json]

<source> may be `owner/repo` or any GitHub URL. Walks the repo tree once, lists
every directory containing a SKILL.md (with its frontmatter description), and
flags settings-bearing entries (hooks/, settings.json, .claude-plugin/, etc.)
so the user knows what else the repo carries. Subscription itself only handles
skills — use subscribe.py with the subpath shown here.
"""

import argparse
import base64
import json
import re

import common as c

# Top-level paths that signal harness "settings" rather than skills.
SETTING_HINTS = (
    "hooks", "settings.json", ".claude-plugin", ".claude/settings.json",
    "agents", "commands", "statusline", "statusLine",
)


def get_tree(repo, ref):
    out = c.run(["gh", "api", f"repos/{repo}/git/trees/{ref}?recursive=1",
                 "--jq", ".tree[] | [.path, .type] | @tsv"])
    items = []
    for line in out.splitlines():
        if "\t" in line:
            path, typ = line.split("\t", 1)
            items.append((path, typ))
    return items


def frontmatter_description(repo, ref, path):
    """Best-effort: pull the `description:` from a SKILL.md frontmatter."""
    try:
        out = c.run(["gh", "api", f"repos/{repo}/contents/{path}?ref={ref}",
                     "--jq", ".content"])
        text = base64.b64decode(out).decode("utf-8", "replace")
    except SystemExit:
        return ""
    # frontmatter is between the first pair of --- lines
    m = re.search(r"^---\s*$(.*?)^---\s*$", text, re.M | re.S)
    block = m.group(1) if m else text[:600]
    dm = re.search(r"^description:\s*(.+?)\s*$", block, re.M | re.S)
    if not dm:
        return ""
    desc = dm.group(1)
    # collapse YAML block scalars / wrapped lines into one line
    desc = re.sub(r"^[>|][-+]?\s*$", "", desc, flags=re.M)
    desc = " ".join(part.strip() for part in desc.splitlines() if part.strip())
    desc = desc.strip().strip('"').strip("'")
    return desc[:200]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("source")
    ap.add_argument("--ref", default=None)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    repo, _, ref = c.parse_source(args.source, None, args.ref)
    if not ref:
        ref = c.gh_default_branch(repo)

    tree = get_tree(repo, ref)

    skills = []
    for path, typ in tree:
        if typ == "blob" and path.endswith("SKILL.md"):
            subpath = path[: -len("/SKILL.md")] if "/" in path else ""
            name = subpath.split("/")[-1] if subpath else repo.split("/")[-1]
            skills.append({
                "name": name,
                "subpath": subpath,
                "description": frontmatter_description(repo, ref, path),
            })
    skills.sort(key=lambda s: s["subpath"])

    top = {p.split("/")[0] for p, _ in tree}
    settings = sorted(h for h in SETTING_HINTS if h.split("/")[0] in top)

    if args.json:
        print(json.dumps({"repo": repo, "ref": ref,
                          "skills": skills, "settings": settings}, indent=2))
        return

    print(f"{repo}@{ref} — {len(skills)} skill(s)\n")
    for i, s in enumerate(skills, 1):
        print(f"{i:>2}. {s['name']}")
        print(f"     path: {s['subpath']}")
        if s["description"]:
            print(f"     {s['description']}")
    if settings:
        print(f"\nsettings present (not auto-subscribed): {', '.join(settings)}")
    print("\nTo subscribe, pick by name/path and run:")
    print(f"  python3 subscribe.py {repo} --subpath <path> [--ref {ref}]")


if __name__ == "__main__":
    main()
