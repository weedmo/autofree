#!/usr/bin/env bash
# UserPromptSubmit — 코딩 키워드 감지 시 Karpathy guidelines 활성화
echo "$PROMPT" | grep -qiE '(write|code|implement|build|create|refactor|review|fix|bug|improve|clean|optimize|rewrite|plan|design|architect|strategy|spec|blueprint|approach|structure|scaffold|skeleton|prototype|draft)' && \
  echo '[Karpathy Guidelines Active] (1) Think Before Coding - state assumptions, surface tradeoffs, ask if unclear (2) Simplicity First - no unnecessary abstractions or speculative features (3) Surgical Changes - only modify what is requested (4) Goal-Driven - define success criteria before implementation' || true
