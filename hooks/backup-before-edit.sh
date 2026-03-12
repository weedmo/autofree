#!/usr/bin/env bash
# PreToolUse: Edit|MultiEdit — 편집 전 백업 생성
if [[ -n "$CLAUDE_TOOL_FILE_PATH" && -f "$CLAUDE_TOOL_FILE_PATH" ]]; then
  mkdir -p .backups
  cp "$CLAUDE_TOOL_FILE_PATH" ".backups/$(basename "$CLAUDE_TOOL_FILE_PATH").$(date +%Y%m%d_%H%M%S).bak"
fi
