"""Shared helpers for the skill-subscribe scripts.

Keeps everything stdlib-only and shells out to `git` / `gh`, so there are no
pip dependencies to install. The manifest is the single source of truth about
which external skills are subscribed and what upstream commit they were pinned
to at install time.
"""

import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

HOME = os.path.expanduser("~")
SKILLS_DIR = os.path.join(HOME, ".claude", "skills")
MANIFEST = os.path.join(SKILLS_DIR, ".skill-subscriptions.json")


# ---------------------------------------------------------------------------
# Manifest I/O
# ---------------------------------------------------------------------------

def load_manifest():
    if not os.path.exists(MANIFEST):
        return {"version": 1, "subscriptions": []}
    with open(MANIFEST) as f:
        return json.load(f)


def save_manifest(data):
    os.makedirs(SKILLS_DIR, exist_ok=True)
    with open(MANIFEST, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")


def find_subscription(data, name):
    for entry in data["subscriptions"]:
        if entry["name"] == name:
            return entry
    return None


# ---------------------------------------------------------------------------
# Source parsing
# ---------------------------------------------------------------------------

def parse_source(source, subpath=None, ref=None):
    """Normalise a user-supplied source into (owner/repo, subpath, ref).

    Accepts shapes like:
      owner/repo
      https://github.com/owner/repo
      https://github.com/owner/repo/tree/<ref>/<subpath>
      git@github.com:owner/repo.git
    An explicit --subpath / --ref always wins over anything parsed from a URL.
    """
    repo = None
    parsed_ref = None
    parsed_sub = None

    s = source.strip()
    m = re.search(r"github\.com[/:]([^/]+)/([^/]+?)(?:\.git)?(?:/(.*))?$", s)
    if m:
        owner, name, rest = m.group(1), m.group(2), m.group(3) or ""
        repo = f"{owner}/{name}"
        # rest may be "tree/<ref>/<path...>" or "blob/<ref>/<path...>"
        tm = re.match(r"(?:tree|blob)/([^/]+)/(.*)$", rest)
        if tm:
            parsed_ref = tm.group(1)
            parsed_sub = tm.group(2).rstrip("/")
        elif rest:
            parsed_sub = rest.rstrip("/")
    elif re.match(r"^[^/]+/[^/]+$", s):
        repo = s
    else:
        die(f"Could not parse a GitHub repo from: {source!r}")

    return (
        repo,
        (subpath or parsed_sub or "").strip("/"),
        ref or parsed_ref or None,
    )


# ---------------------------------------------------------------------------
# GitHub / git
# ---------------------------------------------------------------------------

def gh_default_branch(repo):
    out = run(["gh", "api", f"repos/{repo}", "--jq", ".default_branch"])
    return out.strip() or "main"


def list_repo_skills(repo, ref):
    """Return {skill_name: subpath} for every dir containing a SKILL.md."""
    out = run(["gh", "api", f"repos/{repo}/git/trees/{ref}?recursive=1",
               "--jq", '.tree[] | select(.type=="blob" and (.path|endswith("SKILL.md"))) | .path'])
    skills = {}
    for path in out.splitlines():
        path = path.strip()
        if not path:
            continue
        subpath = path[: -len("/SKILL.md")] if "/" in path else ""
        name = subpath.split("/")[-1] if subpath else repo.split("/")[-1]
        skills[name] = subpath
    return skills


def latest_sha(repo, subpath, ref):
    """Latest commit SHA that touched `subpath` on `ref` (full repo if empty)."""
    path_q = f"&path={subpath}" if subpath else ""
    out = run([
        "gh", "api",
        f"repos/{repo}/commits?sha={ref}&per_page=1{path_q}",
        "--jq", ".[0].sha",
    ])
    sha = out.strip()
    if not sha:
        die(f"No commits found for {repo}@{ref} path={subpath!r}")
    return sha


def fetch_subpath(repo, subpath, ref, dest):
    """Sparse + blobless shallow clone, copy `subpath` into `dest`.

    Returns the path inside the temp clone that was copied, so callers can
    sanity-check it (e.g. that it contains a SKILL.md).
    """
    tmp = tempfile.mkdtemp(prefix="skill-sub-")
    try:
        url = f"https://github.com/{repo}.git"
        run([
            "git", "clone", "--depth", "1", "--branch", ref,
            "--filter=blob:none", "--sparse", url, tmp,
        ])
        if subpath:
            run(["git", "-C", tmp, "sparse-checkout", "set", subpath])
            src = os.path.join(tmp, subpath)
        else:
            src = tmp
        if not os.path.isdir(src):
            die(f"Subpath {subpath!r} not found in {repo}@{ref}")
        if os.path.exists(dest):
            shutil.rmtree(dest)
        # Copy without the .git metadata of the clone root.
        shutil.copytree(src, dest, ignore=shutil.ignore_patterns(".git"))
        return src
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


# ---------------------------------------------------------------------------
# Content hashing (local-edit detection)
# ---------------------------------------------------------------------------

def content_hash(path):
    """Stable hash of a skill directory's file contents (sorted by relpath)."""
    if not os.path.isdir(path):
        return None
    h = hashlib.sha256()
    for root, dirs, files in os.walk(path):
        dirs.sort()
        for fn in sorted(files):
            fp = os.path.join(root, fn)
            rel = os.path.relpath(fp, path)
            h.update(rel.encode())
            try:
                with open(fp, "rb") as f:
                    h.update(f.read())
            except OSError:
                pass
    return h.hexdigest()


# ---------------------------------------------------------------------------
# Small utilities
# ---------------------------------------------------------------------------

def run(cmd, check=True):
    res = subprocess.run(cmd, capture_output=True, text=True)
    if check and res.returncode != 0:
        die(f"Command failed: {' '.join(cmd)}\n{res.stderr.strip()}")
    return res.stdout


def die(msg):
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(1)
