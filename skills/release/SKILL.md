---
name: release
description: "Automated release workflow: version bump, commit, tag, push, GitHub Release, marketplace sync, and cache update"
arguments:
  - name: version
    description: "Version to release (e.g., 1.0.0, patch, minor, major)"
    required: true
---

# Release Workflow

You are performing an automated release of the weed-harness plugin.
The version argument is: `$ARGUMENTS`

## Steps

### 1. Pre-flight Checks

Run these checks and STOP if any fail:

```bash
# Must be on main branch
[ "$(git -C ~/.claude branch --show-current)" = "main" ] || { echo "ERROR: Not on main branch"; exit 1; }

# Working tree must be clean
[ -z "$(git -C ~/.claude status --porcelain)" ] || { echo "ERROR: Working tree is dirty"; exit 1; }

# Fetch latest from origin
git -C ~/.claude fetch origin
```

### 2. Resolve Version

- If the argument is `patch`, `minor`, or `major`: read the current version from `~/.claude/.claude-plugin/plugin.json` and compute the next semver version accordingly.
- If the argument matches `X.Y.Z` format: use it directly.
- Otherwise: STOP with an error.

Store the resolved version as `NEW_VERSION` (without `v` prefix).

### 3. Version Bump

Update these 3 locations with the resolved version:

1. **`~/.claude/.claude-plugin/plugin.json`** → `"version": "NEW_VERSION"`
2. **`~/.claude/.claude-plugin/marketplace.json`** → `metadata.version` field
3. **`~/.claude/.claude-plugin/marketplace.json`** → `plugins[0].version` field

Use the Edit tool for precise replacements. Verify all three values match after editing.

### 4. Commit

```bash
cd ~/.claude
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "chore: bump version to NEW_VERSION"
```

### 5. Tag & Push

```bash
cd ~/.claude
git tag vNEW_VERSION
git push origin main
git push origin vNEW_VERSION
```

### 6. GitHub Release

```bash
cd ~/.claude
gh release create vNEW_VERSION --generate-notes
```

### 7. Marketplace Sync

Pull the latest changes into the local marketplace clone:

```bash
MARKETPLACE_DIR=~/.claude/plugins/marketplaces/weed-plugins
if [ -d "$MARKETPLACE_DIR" ]; then
  git -C "$MARKETPLACE_DIR" fetch origin
  git -C "$MARKETPLACE_DIR" reset --hard origin/main
  echo "Marketplace synced"
else
  echo "WARNING: Marketplace directory not found at $MARKETPLACE_DIR — skipping sync"
fi
```

### 8. Cache Update

Update the local plugin cache so the new version is immediately available:

```bash
CACHE_BASE=~/.claude/plugins/cache/weed-plugins/weed-harness
INSTALLED=~/.claude/plugins/installed_plugins.json

# Remove old cache versions
rm -rf "$CACHE_BASE"/*/

# Create new version cache directory
mkdir -p "$CACHE_BASE/NEW_VERSION"

# Copy plugin files to cache (exclude .git, plugins/, node_modules)
rsync -a --exclude='.git' --exclude='plugins/' --exclude='node_modules/' ~/.claude/ "$CACHE_BASE/NEW_VERSION/"

# Update installed_plugins.json version
if [ -f "$INSTALLED" ]; then
  python3 -c "
import json, sys
with open('$INSTALLED') as f:
    data = json.load(f)
for p in data.get('plugins', []):
    if p.get('name') == 'weed-harness':
        p['version'] = 'NEW_VERSION'
with open('$INSTALLED', 'w') as f:
    json.dump(data, f, indent=2)
print('Updated installed_plugins.json')
"
else
  echo "WARNING: installed_plugins.json not found — skipping"
fi
```

### 9. Verify

Run all verification checks and report results:

```bash
echo "=== Release Verification ==="

# Tag exists
git -C ~/.claude tag -l vNEW_VERSION | grep -q vNEW_VERSION && echo "✓ Tag vNEW_VERSION exists" || echo "✗ Tag missing"

# GitHub Release exists
gh release view vNEW_VERSION --repo weedmo/my_harness &>/dev/null && echo "✓ GitHub Release exists" || echo "✗ GitHub Release missing"

# Cache exists
[ -d ~/.claude/plugins/cache/weed-plugins/weed-harness/NEW_VERSION ] && echo "✓ Cache directory exists" || echo "✗ Cache missing"

# Version in installed_plugins.json
python3 -c "
import json
with open('$HOME/.claude/plugins/installed_plugins.json') as f:
    data = json.load(f)
for p in data.get('plugins', []):
    if p.get('name') == 'weed-harness':
        if p.get('version') == 'NEW_VERSION':
            print('✓ installed_plugins.json version matches')
        else:
            print(f'✗ installed_plugins.json version mismatch: {p.get(\"version\")}')
        break
" 2>/dev/null || echo "✗ Could not verify installed_plugins.json"

echo "=== Release vNEW_VERSION complete ==="
```

Report all results to the user. If any check fails, flag it clearly.
