#!/usr/bin/env bash
# PostToolUse: Bash — git commit 성공 시 TSG 또는 devlog 자동 작성 지시
# 커밋 메시지 키워드로 이슈 해결(TSG) vs 구현 작업(devlog) 구분
# Loop guard: devlog/tsg/pr-verify 관련 커밋은 무시

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_response.exitCode // empty')

if echo "$COMMAND" | grep -qE 'git commit'; then
  if [ "$EXIT_CODE" = "0" ]; then
    # Skip chain-related commits to prevent loops
    if echo "$COMMAND" | grep -qiE 'devlog|DEVLOG|pr-verify|pr.verify|tsg|TSG|docs:.*troubleshooting'; then
      exit 0
    fi

    # Extract commit message from -m flag
    COMMIT_MSG=$(echo "$COMMAND" | sed -n "s/.*-m ['\"]\\(.*\\)['\"].*/\\1/p")
    if [ -z "$COMMIT_MSG" ]; then
      COMMIT_MSG=$(echo "$COMMAND" | sed -n 's/.*-m \([^ ]*\).*/\1/p')
    fi

    # Revert/rollback keywords → devlog reject
    if echo "$COMMIT_MSG" | grep -qiE '(revert|rollback|원복|되돌리기|취소)'; then
      echo '[AUTO-DEVLOG-REJECT] 원복 커밋 감지. 가장 최근 pending 상태의 devlog를 찾아 /devlog reject --auto <ID>를 실행하세요. 거부 사유는 커밋 메시지에서 추출하세요. 사용자 확인 없이 바로 처리하세요.'
    # Issue fix keywords → TSG
    elif echo "$COMMIT_MSG" | grep -qiE '(fix|bug|resolve|hotfix|patch|error|crash|이슈|수정|버그|오류)'; then
      echo '[AUTO-TSG] 이슈 해결 커밋 감지. /devlog tsg --auto를 실행하여 트러블슈팅 가이드를 자동 기록하세요. 사용자 확인 없이 바로 작성하세요.'
    else
      # Implementation/feature → devlog
      echo '[AUTO-DEVLOG] Git commit 완료 감지. /devlog --auto를 실행하여 개발 과정을 자동 기록하세요. 사용자 확인 없이 바로 작성하세요.'
    fi
  fi
fi
