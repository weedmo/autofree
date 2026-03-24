#!/usr/bin/env bash
# UserPromptSubmit — 에러/이슈 키워드 감지 시 TSG 참조 제안

INPUT=$(cat)
USER_PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

echo "$USER_PROMPT" | grep -qiE '(error|에러|오류|fail|crash|bug|버그|exception|traceback|segfault|ENOMEM|timeout|깨짐|안됨|안 됨|문제|issue)' && {
  TSG_DIR="$(git rev-parse --show-toplevel 2>/dev/null)/logs/troubleshooting"
  if [ -d "$TSG_DIR" ] && ls "$TSG_DIR"/*/TSG-*.md >/dev/null 2>&1; then
    echo '[TSG] 에러/이슈 키워드 감지. /tsg search <keyword>로 기존 해결책을 확인하세요.'
  else
    echo '[TSG] 에러/이슈 키워드 감지. 해결 후 /tsg로 기록하거나, 미해결 시 /tsg unresolved로 추적하세요.'
  fi
} || true
