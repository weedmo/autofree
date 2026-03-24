#!/usr/bin/env bash
# PreToolUse: Edit|MultiEdit — 편집 전 백업 생성

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
  mkdir -p .backups
  cp "$FILE_PATH" ".backups/$(basename "$FILE_PATH").$(date +%Y%m%d_%H%M%S).bak"
fi
