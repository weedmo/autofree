---
name: sync
description: "Plugin sync & release: compare local vs GitHub, push changes with auto-release, pull external updates. Use when user wants to update/sync/release any plugin repo (weed-harness, weed-cowork, oh-my-claudecode, document-skills, karpathy-skills) or says 'all' to sync everything."
arguments:
  - name: target
    description: "Plugin to sync: weed-harness, weed-cowork, oh-my-claudecode, document-skills, karpathy-skills, or 'all'"
    required: true
---

# Sync Workflow

You are syncing plugin repos. The target argument is: `$ARGUMENTS`

## Repo Mapping

### Own repos (push direction)

| Alias | GitHub Repo | Local Path | Cache Key |
|-------|------------|------------|-----------|
| `weed-harness` | `weedmo/my_harness` | `~/.claude/` | `weed-harness@weed-plugins` |
| `weed-cowork` | `weedmo/my_cowork` | `~/repos/my_cowork/` | `weed-cowork@weed-plugins` |

### External repos (pull direction)

| Alias | GitHub Repo | Marketplace Clone | Cache Key |
|-------|-------------|-------------------|-----------|
| `oh-my-claudecode` | `Yeachan-Heo/oh-my-claudecode` | `~/.claude/plugins/marketplaces/omc/` | `oh-my-claudecode@weed-plugins` |
| `document-skills` | `anthropics/skills` | `~/.claude/plugins/marketplaces/anthropic-agent-skills/` | `document-skills@weed-plugins` |
| `karpathy-skills` | `forrestchang/andrej-karpathy-skills` | `~/.claude/plugins/marketplaces/karpathy-skills/` | `andrej-karpathy-skills@weed-plugins` |

## Target Resolution

- If target is `all`: process own repos first (weed-harness, weed-cowork), then external repos (oh-my-claudecode, document-skills, karpathy-skills). Own repos first because marketplace.json changes may need to be pushed.
- If target matches an alias above: process only that repo.
- Otherwise: STOP with an error listing valid targets.

---

## Workflow A: Own Repos (weed-harness, weed-cowork)

### A1. Pre-flight Checks

```bash
# Set LOCAL_PATH based on alias
# weed-harness → ~/.claude/
# weed-cowork → ~/repos/my_cowork/
```

- If the local path does not exist: report "Local clone not found at LOCAL_PATH. Run `git clone git@github.com:GITHUB_REPO.git LOCAL_PATH` first." and STOP (skip this repo in `all` mode).
- `git -C LOCAL_PATH fetch origin`
- Compare local HEAD vs origin/main. If identical and working tree is clean: report "already in sync" and STOP (skip in `all` mode).

### A2. Dirty Guard

```bash
DIRTY=$(git -C LOCAL_PATH status --porcelain)
```

- If working tree is dirty: report "Working tree is dirty. Run `/commit` first to commit your changes." and STOP (skip in `all` mode).

### A3. Version Resolve

```bash
# Get latest tag from GitHub
LATEST_TAG=$(git -C LOCAL_PATH describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
# Strip 'v' prefix
LATEST_VER=${LATEST_TAG#v}
```

- Read current version from `LOCAL_PATH/.claude-plugin/plugin.json`.
- If plugin.json version > latest tag version: use plugin.json version as-is (manual bump case).
- Otherwise: auto-increment patch from latest tag (e.g., 0.0.1 → 0.0.2).
- Store as `NEW_VERSION` (without `v` prefix).

### A4. Version Bump

Update these locations with NEW_VERSION using the Edit tool:

**For weed-harness:**
1. `~/.claude/.claude-plugin/plugin.json` → `"version": "NEW_VERSION"`
2. `~/.claude/.claude-plugin/marketplace.json` → root `"version"` field
3. `~/.claude/.claude-plugin/marketplace.json` → `plugins[name="weed-harness"].version`

**For weed-cowork:**
1. `~/repos/my_cowork/.claude-plugin/plugin.json` → `"version": "NEW_VERSION"`
2. `~/repos/my_cowork/.claude-plugin/marketplace.json` → `metadata.version` field
3. `~/repos/my_cowork/.claude-plugin/marketplace.json` → `plugins[name="weed-cowork"].version`
4. **Cross-repo**: `~/.claude/.claude-plugin/marketplace.json` → `plugins[name="weed-cowork"].version`
   (weed-cowork is registered as URL source in weed-plugins marketplace for update detection)

Verify all updated values match after editing.

### A5. Commit & Push Target Repo

```bash
cd LOCAL_PATH
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "chore: bump version to NEW_VERSION"
git tag vNEW_VERSION
git push origin main
git push origin vNEW_VERSION
```

Do NOT include Co-Authored-By lines.

### A6. Cross-Repo Marketplace Update (weed-cowork only)

**This step only applies when syncing weed-cowork.** Skip for weed-harness.

After pushing weed-cowork, the harness marketplace.json was modified in A4 step 4.
Commit and push harness to keep marketplace.json in sync:

```bash
cd ~/.claude
git add .claude-plugin/marketplace.json
git commit -m "chore: update weed-cowork version to NEW_VERSION in marketplace"
git push origin main
```

### A7. GitHub Release

```bash
cd LOCAL_PATH
gh release create vNEW_VERSION --generate-notes
```

### A6. Marketplace Sync (MANDATORY)

This step MUST always run after any release. It syncs the local marketplace clone with the remote.

Both own repos use the weed-plugins marketplace clone (weed-cowork is registered there as a URL source):

```bash
MARKETPLACE_DIR=~/.claude/plugins/marketplaces/weed-plugins
if [ -d "$MARKETPLACE_DIR" ]; then
  git -C "$MARKETPLACE_DIR" fetch origin
  git -C "$MARKETPLACE_DIR" reset --hard origin/main
  echo "Marketplace synced to $(git -C "$MARKETPLACE_DIR" rev-parse --short HEAD)"
else
  echo "ERROR: Marketplace directory not found at $MARKETPLACE_DIR — this must be fixed"
fi
```

### A9. Cache Update

```bash
CACHE_KEY="ALIAS"  # e.g. weed-harness or weed-cowork
CACHE_BASE=~/.claude/plugins/cache/weed-plugins/$CACHE_KEY
INSTALLED=~/.claude/plugins/installed_plugins.json

# Remove old cache versions
rm -rf "$CACHE_BASE"/*/

# Create new version cache directory
mkdir -p "$CACHE_BASE/$NEW_VERSION"

# Copy plugin files to cache (exclude .git, plugins/, node_modules)
rsync -a --exclude='.git' --exclude='plugins/' --exclude='node_modules/' LOCAL_PATH/ "$CACHE_BASE/$NEW_VERSION/"
```

Update `installed_plugins.json`:

```python
import json, datetime
INSTALLED = "~/.claude/plugins/installed_plugins.json"  # expand ~ in actual command
CACHE_KEY = "ALIAS@weed-plugins"  # e.g. weed-harness@weed-plugins
with open(INSTALLED) as f:
    data = json.load(f)
entry = data["plugins"][CACHE_KEY][0]
entry["version"] = NEW_VERSION
entry["installPath"] = f"/home/weed/.claude/plugins/cache/weed-plugins/ALIAS/{NEW_VERSION}"
entry["lastUpdated"] = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.000Z")
entry["gitCommitSha"] = GIT_SHA  # from git rev-parse HEAD
with open(INSTALLED, "w") as f:
    json.dump(data, f, indent=2)
```

### A10. Verify

Check and report:
- Tag `vNEW_VERSION` exists locally
- GitHub Release exists (`gh release view vNEW_VERSION --repo GITHUB_REPO`)
- Cache directory exists at expected path
- `installed_plugins.json` version matches NEW_VERSION

---

## Workflow B: External Repos (oh-my-claudecode, document-skills, karpathy-skills)

### B1. Version Check

```bash
MARKETPLACE_CLONE="path from repo mapping"
CACHE_KEY="key from repo mapping"  # note: karpathy-skills uses andrej-karpathy-skills@weed-plugins
```

- `git -C MARKETPLACE_CLONE fetch origin`
- Get latest remote HEAD SHA: `git -C MARKETPLACE_CLONE rev-parse origin/main`
- Read current SHA from `installed_plugins.json` → `plugins[CACHE_KEY][0].gitCommitSha`
- If they match: report "already up-to-date" and STOP (skip in `all` mode).

### B2. Marketplace Clone Update

```bash
git -C MARKETPLACE_CLONE reset --hard origin/main
```

### B3. Version String

```bash
# Try to get latest semver tag
LATEST_TAG=$(git -C MARKETPLACE_CLONE describe --tags --abbrev=0 2>/dev/null)
if [ -n "$LATEST_TAG" ]; then
  NEW_VERSION="${LATEST_TAG#v}"  # strip v prefix
else
  # No tags — use 12-char commit SHA
  NEW_VERSION=$(git -C MARKETPLACE_CLONE rev-parse --short=12 HEAD)
fi
NEW_SHA=$(git -C MARKETPLACE_CLONE rev-parse HEAD)
```

### B4. Cache Update

```bash
# Derive CACHE_NAME from CACHE_KEY (strip @weed-plugins suffix)
CACHE_NAME="${CACHE_KEY%@weed-plugins}"
CACHE_BASE=~/.claude/plugins/cache/weed-plugins/$CACHE_NAME

# Remove old cache versions
rm -rf "$CACHE_BASE"/*/

# Create new version cache directory
mkdir -p "$CACHE_BASE/$NEW_VERSION"

# Copy plugin files (exclude .git)
rsync -a --exclude='.git' MARKETPLACE_CLONE/ "$CACHE_BASE/$NEW_VERSION/"
```

### B5. Update installed_plugins.json

```python
import json, datetime
INSTALLED = "/home/weed/.claude/plugins/installed_plugins.json"
with open(INSTALLED) as f:
    data = json.load(f)
entry = data["plugins"][CACHE_KEY][0]
entry["version"] = NEW_VERSION
entry["installPath"] = f"/home/weed/.claude/plugins/cache/weed-plugins/{CACHE_NAME}/{NEW_VERSION}"
entry["lastUpdated"] = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.000Z")
entry["gitCommitSha"] = NEW_SHA
with open(INSTALLED, "w") as f:
    json.dump(data, f, indent=2)
```

### B6. Verify

Check and report:
- Cache directory exists at `CACHE_BASE/NEW_VERSION`
- `installed_plugins.json` version matches NEW_VERSION
- `installed_plugins.json` gitCommitSha matches NEW_SHA

---

## Error Handling

- In `all` mode: if one repo fails, log the error and continue to the next. Report a summary at the end listing successes and failures.
- Network errors: report the error clearly and skip to the next repo.

## Final Report

After processing all targets, print a summary table:

```
=== Sync Summary ===
weed-harness    : v0.0.2 → pushed + released
oh-my-claudecode: v4.8.0 → cache updated
document-skills : already up-to-date
...
```
