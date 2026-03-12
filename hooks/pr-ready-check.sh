#!/usr/bin/env bash
# PreToolUse: Bash — gh pr create 감지 시 /pr-ready 리마인더
if echo "$CLAUDE_TOOL_INPUT" | grep -q 'gh pr create'; then
  echo '[pr-ready reminder] gh pr create 감지됨. /pr-ready를 먼저 실행하여 테스트 통과 및 검토자용 가이드 작성을 권장합니다.'
fi
