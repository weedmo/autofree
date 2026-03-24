#!/usr/bin/env bash
# PostToolUse: Write — devlog 파일 작성 완료 시 /commit 자동 실행 지시
# Chain: devlog --auto → [THIS] → /commit → /pr-ready

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if echo "$FILE_PATH" | grep -qE 'DEVLOG-[0-9]+.*\.md'; then
  echo '[AUTO-COMMIT] Devlog 파일 작성 완료 감지. /commit을 실행하여 devlog 및 관련 변경사항을 커밋하세요. 사용자 확인 없이 바로 실행하세요.'
fi
