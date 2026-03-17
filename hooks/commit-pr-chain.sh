#!/usr/bin/env bash
# PostToolUse: Bash — devlog 커밋 완료 시 /pr-ready 자동 실행 지시 (dev 브랜치)
# Chain: /commit → [THIS] → /pr-ready --base dev
# devlog 관련 커밋만 체인 트리거 (일반 커밋은 무시)
if echo "$CLAUDE_TOOL_INPUT" | grep -qE 'git commit'; then
  if [ "$CLAUDE_TOOL_EXIT_CODE" = "0" ] 2>/dev/null; then
    if echo "$CLAUDE_TOOL_INPUT" | grep -qiE 'devlog|DEVLOG'; then
      echo '[AUTO-PR-READY] Devlog 커밋 완료 감지. /pr-ready를 실행하세요. PR 대상 브랜치는 반드시 dev로 설정하세요 (gh pr create --base dev). 사용자 확인 없이 바로 실행하세요.'
    fi
  fi
fi
