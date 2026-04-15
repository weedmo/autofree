#!/bin/bash
# Hook: PostToolUse:Bash — detect git merge conflicts and trigger merge-resolve skill
# Reads $CLAUDE_TOOL_OUTPUT from stdin

INPUT=$(cat)
TOOL_OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // empty' 2>/dev/null)

# Check if this was a merge command that produced conflicts
if echo "$TOOL_OUTPUT" | grep -qE '(CONFLICT|Automatic merge failed|fix conflicts and then commit)'; then
  echo "[MAGIC KEYWORD: merge-resolve]"
fi
