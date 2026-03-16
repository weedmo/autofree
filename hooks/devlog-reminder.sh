#!/usr/bin/env bash
# PostToolUse: Bash — git commit 성공 시 devlog 리마인더
if echo "$CLAUDE_TOOL_INPUT" | grep -qE 'git commit'; then
  if [ "$CLAUDE_TOOL_EXIT_CODE" = "0" ] 2>/dev/null; then
    echo '[devlog] 커밋 완료 감지. 개발 과정을 기록하려면 /devlog를 실행하세요.'
  fi
fi
