#!/usr/bin/env bash
# UserPromptSubmit: Detect non-trivial tasks without explicit skill invocation
# Triggers skill-recommend when user gives a complex task without /command prefix

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

# Skip if empty
[ -z "$PROMPT" ] && exit 0

# Skip if user already invoked a skill with /
if echo "$PROMPT" | grep -qE '^\s*/[a-zA-Z]'; then
  exit 0
fi

# Skip simple/short prompts (under 15 chars likely greeting or simple question)
if [ ${#PROMPT} -lt 15 ]; then
  exit 0
fi

# Skip greetings, simple questions, confirmations
if echo "$PROMPT" | grep -qiE '^(hi|hello|hey|안녕|ㅎㅇ|네|응|ㅇㅇ|ok|yes|no|아니|감사|ㄱㅅ|ㅊㅋ|good|thanks|y$|n$|[0-9]+$)'; then
  exit 0
fi

# Skip "just do it" style prompts
if echo "$PROMPT" | grep -qiE '(바로 진행|그냥 해|just do it|이어서|계속|진행|실행해줘|ㄱㄱ)'; then
  exit 0
fi

# Skip follow-up responses (short confirmations, number selections)
if echo "$PROMPT" | grep -qE '^\s*[0-9]{1,2}\s*$'; then
  exit 0
fi

# Detect complex task signals (multi-step, specialized domain)
COMPLEX=0

# Implementation keywords
echo "$PROMPT" | grep -qiE '(만들어|구현|개발|작성|생성|리팩토링|최적화|배포|리뷰|분석|설계|create|implement|build|deploy|refactor|optimize|review|analyze|design)' && COMPLEX=1

# File type mentions (with or without dot prefix)
echo "$PROMPT" | grep -qiE '(\.pdf|\.xlsx|\.docx|\.pptx|\.csv|PDF|XLSX|DOCX|PPTX|CSV|pdf|xlsx|docx|pptx|\.py|\.ts|\.js|\.go|\.rs|\.kt|\.java|\.cpp)' && COMPLEX=1

# Domain keywords
echo "$PROMPT" | grep -qiE '(API|database|인증|보안|테스트|CI/CD|Docker|ML|모델|파이프라인|에이전트|agent|pipeline|security|auth)' && COMPLEX=1

# Long prompts (50+ chars) with action verbs
if [ ${#PROMPT} -gt 50 ]; then
  echo "$PROMPT" | grep -qiE '(해줘|해주세요|하고 싶|할 수 있|please|want to|need to|how to)' && COMPLEX=1
fi

# Only trigger if complex task detected
if [ "$COMPLEX" -eq 1 ]; then
  echo '[SKILL-RECOMMEND] 스킬을 지정하지 않은 복합 작업 감지. /skill-recommend를 실행하여 이 작업에 적합한 스킬을 추천하세요.'
fi
