#!/usr/bin/env bash
# UserPromptSubmit — 코딩 키워드 감지 시 Karpathy guidelines 활성화

INPUT=$(cat)
USER_PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

echo "$USER_PROMPT" | grep -qiE '(write|code|implement|build|create|refactor|review|fix|bug|improve|clean|optimize|rewrite|plan|design|architect|strategy|spec|blueprint|approach|structure|scaffold|skeleton|prototype|draft)' && \
  echo '[Karpathy] Simplicity, Surgical, Goal-Driven' || true
