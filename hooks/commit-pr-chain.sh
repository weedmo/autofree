#!/usr/bin/env bash
# PostToolUse: Bash — devlog/TSG 커밋 완료 시 자동 브랜치 생성 + PR 지시
# Chain: /commit → [THIS] → branch + push + gh pr create --base dev

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_response.exitCode // empty')

if echo "$COMMAND" | grep -qE 'git commit'; then
  if [ "$EXIT_CODE" = "0" ]; then
    # Detect devlog or TSG commits
    DOC_TYPE=""
    if echo "$COMMAND" | grep -qiE 'devlog|DEVLOG'; then
      DOC_TYPE="devlog"
    elif echo "$COMMAND" | grep -qiE 'tsg|TSG|troubleshoot'; then
      DOC_TYPE="tsg"
    fi

    if [ -n "$DOC_TYPE" ]; then
      CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
      PR_TITLE="docs: add ${DOC_TYPE} entry"

      if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
        BRANCH_NAME="${DOC_TYPE}/$(date +%Y%m%d-%H%M%S)"
        echo "[AUTO-PR] main 브랜치에서 ${DOC_TYPE} 커밋 감지. 다음을 순서대로 실행하세요: (1) git checkout -b ${BRANCH_NAME} (2) git push -u origin ${BRANCH_NAME} (3) gh pr create --base dev --title '${PR_TITLE}' --body 'Auto-generated ${DOC_TYPE} entry'. 사용자 확인 없이 바로 실행하세요."
      else
        echo "[AUTO-PR] ${DOC_TYPE} 커밋 완료 감지. 다음을 순서대로 실행하세요: (1) git push -u origin ${CURRENT_BRANCH} (2) gh pr create --base dev --title '${PR_TITLE}' --body 'Auto-generated ${DOC_TYPE} entry'. 사용자 확인 없이 바로 실행하세요."
      fi
    fi
  fi
fi
