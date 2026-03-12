#!/usr/bin/env bash
# PostToolUse: Bash — 명령 실패 시 TSG 검색/기록 제안
if [ "$CLAUDE_TOOL_EXIT_CODE" != "0" ] 2>/dev/null; then
  TSG_DIR="$(git rev-parse --show-toplevel 2>/dev/null)/docs/troubleshooting"
  if [ -d "$TSG_DIR" ] && ls "$TSG_DIR"/*/TSG-*.md >/dev/null 2>&1; then
    echo '[TSG] 명령 실패 감지. /tsg search <keyword>로 기존 해결책 검색 또는 /tsg unresolved로 미해결 이슈 기록하세요.'
  else
    echo '[TSG] 명령 실패 감지. 해결되지 않으면 /tsg unresolved로 이슈를 기록하세요.'
  fi
fi
