#!/usr/bin/env bash
# PostToolUse: Bash — git commit 성공 시 devlog 자동 작성 지시
# 기존 devlog-reminder.sh를 대체: 리마인더 → directive
# Loop guard: devlog/pr-verify 관련 커밋은 무시 (체인 루프 방지)
if echo "$CLAUDE_TOOL_INPUT" | grep -qE 'git commit'; then
  if [ "$CLAUDE_TOOL_EXIT_CODE" = "0" ] 2>/dev/null; then
    # Skip devlog-related or pr-verify commits to prevent chain loops
    if echo "$CLAUDE_TOOL_INPUT" | grep -qiE 'devlog|DEVLOG|pr-verify|pr.verify'; then
      exit 0
    fi
    echo '[AUTO-DEVLOG] Git commit 완료 감지. /devlog --auto를 실행하여 개발 과정을 자동 기록하세요. 사용자 확인 없이 바로 작성하세요.'
  fi
fi
