# CLAUDE.md 템플릿
# 이 파일을 프로젝트 루트에 CLAUDE.md로 복사하여 사용하세요.
# 팀 오케스트레이터(team-dispatch)가 이 파일을 읽고 규칙을 따릅니다.
# `/init` 스킬로 자동 생성할 수도 있습니다.

## 프로젝트 정보
- 이름:
- 언어: Python / TypeScript / Rust / Go / C++ / C
- 프레임워크:

## 런타임 (runtime)
# 언어 및 런타임 버전 정보. /init으로 자동 감지 가능.
# - python: 3.12.1
# - node: 20.11.0
# - rust: 1.75.0
# - go: 1.22.0
# - package_manager: uv / poetry / npm / yarn / pnpm / bun / cargo

## 의존성 (dependencies)

### Production
# 허용된 프로덕션 라이브러리. 여기에 없는 것은 설치하지 않음.
# 예시:
# - fastapi==0.109.0
# - sqlalchemy==2.0.25
# - pydantic==2.5.3

### Development
# 개발 의존성 (테스트, 린터, 포매터 등)
# 예시:
# - pytest==8.0.0
# - ruff==0.2.0
# - mypy==1.8.0

## 빌드 도구 (toolchain)
# 테스트, 린트, 빌드에 사용하는 도구. /init으로 자동 감지 가능.
# - test_command: pytest / npm test / cargo test / go test ./...
# - test_framework: pytest / jest / vitest / cargo test
# - linter: ruff / eslint / clippy / golangci-lint
# - formatter: ruff format / prettier / rustfmt / gofmt
# - type_checker: mypy / pyright / tsc
# - pre_commit: true/false
# - ci: github-actions / gitlab-ci / none

## 컨벤션 (conventions)
# 코딩 스타일 규칙
# - naming: snake_case / camelCase / PascalCase
# - max_line_length: 88 / 100 / 120
# - max_function_length: 50
# - indent: spaces 4 / spaces 2 / tabs
# - quotes: single / double
# - docstring: google / numpy / sphinx

## 아키텍처 (architecture)
# 디렉토리 구조 규칙
# 예시:
# src/
#   models/      - 데이터 모델
#   services/    - 비즈니스 로직
#   api/         - API 엔드포인트
#   utils/       - 유틸리티
# tests/
#   unit/
#   integration/

## 제약사항 (constraints)
# 금지된 패턴이나 라이브러리
# - no global state
# - no print() in production code (use logging)
# - no * imports

## 테스트 설정 (test)
# - test_command: pytest / npm test / cargo test
# - test_framework: pytest / jest / vitest
# - min_coverage: 80
# - pre_commit: true/false

## 리팩토링 규칙 (refactor)
# Refactor Mode가 따를 추가 규칙
# - max_file_lines: 300
# - max_function_lines: 30
# - max_class_methods: 10
# - prefer_composition: true

## 생성 정보 (generated)
# /init 스킬로 자동 생성 시 기록되는 메타데이터
# - generated_by: /init
# - generated_at: 2026-02-13
# - detection_method: auto
