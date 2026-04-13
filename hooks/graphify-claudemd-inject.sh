#!/usr/bin/env bash
# PostToolUse hook: After /graphify skill runs, inject graphify section into project CLAUDE.md
# Trigger: PostToolUse on Skill tool when graphify skill is invoked

set -euo pipefail

# Only process Skill tool calls
[[ "${CLAUDE_TOOL_NAME:-}" == "Skill" ]] || exit 0

# Check if the skill invoked was graphify
INPUT="${CLAUDE_TOOL_INPUT:-}"
if ! echo "$INPUT" | grep -q '"graphify"'; then
  exit 0
fi

# Find project CLAUDE.md (look for .git root or use current dir)
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CLAUDE_MD="$PROJECT_ROOT/CLAUDE.md"
GRAPHIFY_OUT="$PROJECT_ROOT/graphify-out"

# Only proceed if graphify-out/ exists (meaning graphify ran successfully)
if [[ ! -d "$GRAPHIFY_OUT" ]]; then
  exit 0
fi

# The graphify section to inject
GRAPHIFY_SECTION='## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- Before answering architecture or codebase questions, read graphify-out/GRAPH_REPORT.md for god nodes and community structure
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- After modifying code files in this session, run `python3 -c "from graphify.watch import _rebuild_code; from pathlib import Path; _rebuild_code(Path('"'"'.'"'"'))"` to keep the graph current'

# Check if graphify section already exists
if [[ -f "$CLAUDE_MD" ]] && grep -q '## graphify' "$CLAUDE_MD"; then
  # Already has graphify section - replace it
  # Remove existing section (from ## graphify to next ## or EOF)
  python3 -c "
import re, sys
with open('$CLAUDE_MD', 'r') as f:
    content = f.read()
# Remove existing graphify section (## graphify to next ## heading or EOF)
pattern = r'## graphify\n.*?(?=\n## |\Z)'
cleaned = re.sub(pattern, '', content, flags=re.DOTALL).rstrip()
section = '''$GRAPHIFY_SECTION'''
with open('$CLAUDE_MD', 'w') as f:
    f.write(cleaned + '\n\n' + section + '\n')
"
else
  # No existing section - append
  if [[ -f "$CLAUDE_MD" ]]; then
    printf '\n\n%s\n' "$GRAPHIFY_SECTION" >> "$CLAUDE_MD"
  else
    printf '%s\n' "$GRAPHIFY_SECTION" > "$CLAUDE_MD"
  fi
fi

exit 0
