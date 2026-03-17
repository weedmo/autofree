#!/usr/bin/env bash
# PostToolUse: MCP state_clear — OMC 모드 완료 시 devlog 자동 작성 지시
# state_clear 호출 = OMC 모드(autopilot, ralph, ultrawork, team 등) 종료
# /cancel로 취소된 경우에도 트리거 (작업 과정 자체가 기록 가치 있음)
echo '[AUTO-DEVLOG] OMC 모드 완료 감지. /devlog --auto를 실행하여 개발 과정을 자동 기록하세요. 사용자 확인 없이 바로 작성하세요.'
