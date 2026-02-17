# /init - 프로젝트 의존성 자동 감지 및 CLAUDE.md 생성

프로젝트 루트에서 런타임 버전, 의존성(prod+dev), 프레임워크, 빌드 도구를 자동 감지하여 CLAUDE.md를 생성한다.
팀 에이전트(feature-mode, refactor-mode, test-mode)가 정확한 버전 정보를 기반으로 작업할 수 있도록 한다.

## 실행 단계

아래 단계를 **순서대로** 수행한다. 각 단계에서 수집한 정보를 변수로 저장하고 최종 CLAUDE.md에 반영한다.

---

### Step 1: 프로젝트 루트 확인

1. 현재 디렉토리가 프로젝트 루트인지 확인 (`.git`, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `CMakeLists.txt` 중 하나 존재)
2. 프로젝트 이름 추출: 디렉토리명 또는 설정 파일에서
3. 이미 `CLAUDE.md`가 존재하면 사용자에게 덮어쓰기 확인 (AskUserQuestion 사용)

---

### Step 2: 언어/런타임 감지

아래 순서로 주요 언어를 판별하고 버전을 수집:

| 언어 | 감지 파일 | 런타임 버전 명령 | 설정 파일 버전 |
|------|-----------|-----------------|---------------|
| Python | `pyproject.toml`, `setup.py`, `requirements.txt`, `Pipfile` | `python3 --version` | `pyproject.toml` → `requires-python` |
| Node.js | `package.json`, `tsconfig.json` | `node --version` | `package.json` → `engines.node` |
| TypeScript | `tsconfig.json` | `npx tsc --version` | `tsconfig.json` → `compilerOptions.target` |
| Rust | `Cargo.toml` | `rustc --version` | `rust-toolchain.toml`, `Cargo.toml` → `edition` |
| Go | `go.mod` | `go version` | `go.mod` → `go` directive |
| C/C++ | `CMakeLists.txt`, `Makefile`, `*.c`, `*.cpp` | `gcc --version` 또는 `g++ --version` | `CMakeLists.txt` → `CMAKE_CXX_STANDARD` |

**수집 항목:**
- `language`: 주요 언어 (여러 개일 수 있음)
- `runtime_version`: 런타임 버전
- `framework`: 프레임워크 (아래 Step에서 감지)

---

### Step 3: 프레임워크 감지

의존성 파일에서 프레임워크를 식별:

| 프레임워크 | 감지 기준 |
|-----------|----------|
| FastAPI | `fastapi` in dependencies |
| Django | `django` in dependencies |
| Flask | `flask` in dependencies |
| React | `react` in package.json dependencies |
| Next.js | `next` in package.json dependencies |
| Vue | `vue` in package.json dependencies |
| Svelte | `svelte` in package.json dependencies |
| Express | `express` in package.json dependencies |
| NestJS | `@nestjs/core` in package.json dependencies |
| Actix | `actix-web` in Cargo.toml dependencies |
| Axum | `axum` in Cargo.toml dependencies |
| Gin | `github.com/gin-gonic/gin` in go.mod |
| Echo | `github.com/labstack/echo` in go.mod |

---

### Step 4: 의존성 파싱

의존성 파일에서 **prod와 dev를 구분**하여 전체 목록 수집:

#### Python
- `pyproject.toml`:
  - prod → `[project.dependencies]`
  - dev → `[project.optional-dependencies.dev]` 또는 `[project.optional-dependencies.test]`
  - tool settings → `[tool.ruff]`, `[tool.mypy]`, `[tool.pytest]` 등
- `requirements.txt` → prod (전체)
- `requirements-dev.txt` → dev
- `Pipfile`:
  - prod → `[packages]`
  - dev → `[dev-packages]`
- `setup.cfg` / `setup.py` → `install_requires`, `extras_require`

#### Node.js
- `package.json`:
  - prod → `dependencies`
  - dev → `devDependencies`

#### Rust
- `Cargo.toml`:
  - prod → `[dependencies]`
  - dev → `[dev-dependencies]`

#### Go
- `go.mod`:
  - prod → `require` 블록 전체

#### C/C++
- `CMakeLists.txt` → `find_package(...)` 목록
- `conanfile.txt` / `conanfile.py` → `[requires]`
- `vcpkg.json` → `dependencies`

---

### Step 5: 패키지 매니저 감지

| 매니저 | 감지 기준 |
|--------|----------|
| uv | `uv.lock` 존재 또는 `pyproject.toml`에 `[tool.uv]` |
| poetry | `poetry.lock` 존재 또는 `pyproject.toml`에 `[tool.poetry]` |
| pip | `requirements.txt` 존재 (uv/poetry 아닐 때) |
| pipenv | `Pipfile.lock` 존재 |
| npm | `package-lock.json` 존재 |
| yarn | `yarn.lock` 존재 |
| pnpm | `pnpm-lock.yaml` 존재 |
| bun | `bun.lockb` 또는 `bun.lock` 존재 |
| cargo | `Cargo.lock` 존재 |

---

### Step 6: 빌드/테스트/린트 도구 감지

#### 테스트 프레임워크
| 도구 | 감지 기준 |
|------|----------|
| pytest | `pytest` in dependencies 또는 `[tool.pytest]` in pyproject.toml |
| unittest | `import unittest` in test files |
| jest | `jest` in devDependencies 또는 `jest.config.*` 존재 |
| vitest | `vitest` in devDependencies 또는 `vitest.config.*` 존재 |
| mocha | `mocha` in devDependencies |
| cargo test | Rust 프로젝트이면 기본 |
| go test | Go 프로젝트이면 기본 |

#### 린터/포매터
| 도구 | 감지 기준 |
|------|----------|
| ruff | `ruff` in dependencies 또는 `[tool.ruff]` in pyproject.toml |
| black | `black` in dependencies 또는 `[tool.black]` in pyproject.toml |
| isort | `isort` in dependencies |
| flake8 | `flake8` in dependencies 또는 `.flake8` 존재 |
| mypy | `mypy` in dependencies 또는 `[tool.mypy]` in pyproject.toml |
| pyright | `pyright` in dependencies 또는 `pyrightconfig.json` 존재 |
| eslint | `eslint` in devDependencies 또는 `.eslintrc*` / `eslint.config.*` 존재 |
| prettier | `prettier` in devDependencies 또는 `.prettierrc*` 존재 |
| biome | `@biomejs/biome` in devDependencies 또는 `biome.json` 존재 |
| rustfmt | `rustfmt.toml` 존재 또는 Rust 프로젝트 기본 |
| clippy | Rust 프로젝트 기본 |
| gofmt | Go 프로젝트 기본 |
| golangci-lint | `.golangci.yml` 또는 `.golangci.yaml` 존재 |

#### 기타 도구
| 도구 | 감지 기준 |
|------|----------|
| pre-commit | `.pre-commit-config.yaml` 존재 |
| husky | `.husky/` 디렉토리 또는 `husky` in devDependencies |
| lint-staged | `lint-staged` in package.json |
| GitHub Actions | `.github/workflows/` 디렉토리 존재 |
| GitLab CI | `.gitlab-ci.yml` 존재 |
| Docker | `Dockerfile` 또는 `docker-compose.yml` 존재 |
| Makefile | `Makefile` 존재 |

---

### Step 7: 컨벤션 자동 추출

기존 린터/포매터 설정에서 코딩 컨벤션을 추출:

#### Python (`pyproject.toml`)
```
[tool.ruff] 또는 [tool.ruff.lint]
→ line-length → max_line_length
→ select → 활성화된 규칙

[tool.black]
→ line-length → max_line_length

[tool.isort]
→ profile → import 스타일

[tool.mypy]
→ strict → 타입 체크 엄격도
```

#### Node.js
```
.eslintrc* / eslint.config.*
→ rules → 코딩 규칙
→ indent → 들여쓰기

.prettierrc*
→ printWidth → max_line_length
→ tabWidth → indent
→ singleQuote → quotes
→ semi → semicolon
```

#### Rust
```
rustfmt.toml
→ max_width → max_line_length
→ tab_spaces → indent
→ edition → Rust edition
```

#### Go
```
.golangci.yml
→ linters → 활성화된 린터
→ linters-settings → 세부 설정
```

**기본값 (감지 실패 시):**
- Python: snake_case, 88자, spaces 4, double quotes
- JavaScript/TypeScript: camelCase, 80자, spaces 2
- Rust: snake_case, 100자, spaces 4
- Go: camelCase (exported PascalCase), gofmt 기본

---

### Step 8: 테스트 명령어 조립

감지된 도구를 바탕으로 테스트 실행 명령어를 결정:

```
Python + pytest → test_command: "pytest"
Python + uv + pytest → test_command: "uv run pytest"
Python + poetry + pytest → test_command: "poetry run pytest"
Node + jest → test_command: "npx jest" 또는 "npm test"
Node + vitest → test_command: "npx vitest"
Rust → test_command: "cargo test"
Go → test_command: "go test ./..."
```

lint 명령어도 동일하게:
```
Python + ruff → lint_command: "ruff check .", format_command: "ruff format ."
Node + eslint → lint_command: "npx eslint ."
Node + prettier → format_command: "npx prettier --write ."
Rust → lint_command: "cargo clippy", format_command: "cargo fmt"
Go → lint_command: "golangci-lint run", format_command: "gofmt -w ."
```

---

### Step 9: CLAUDE.md 생성

수집된 모든 정보를 아래 형식으로 CLAUDE.md에 작성:

```markdown
# CLAUDE.md
# Generated by /init on {현재 날짜}

## 프로젝트 정보
- 이름: {프로젝트명}
- 언어: {주요 언어}
- 프레임워크: {프레임워크}

## 런타임 (runtime)
- {언어}: {버전}
- package_manager: {패키지 매니저}

## 의존성 (dependencies)

### Production
{prod 의존성 목록, 각 줄에 - name==version 형식}

### Development
{dev 의존성 목록, 각 줄에 - name==version 형식}

## 빌드 도구 (toolchain)
- test_command: {테스트 명령어}
- test_framework: {테스트 프레임워크}
- linter: {린터}
- formatter: {포매터}
- type_checker: {타입 체커} (있으면)
- pre_commit: {true/false}
- ci: {GitHub Actions / GitLab CI / none}

## 컨벤션 (conventions)
- naming: {네이밍 컨벤션}
- max_line_length: {최대 줄 길이}
- indent: {들여쓰기 방식}
- quotes: {따옴표 스타일} (해당 언어에 적용되면)

## 아키텍처 (architecture)
# 사용자가 수동으로 작성하세요.
# 예시:
# src/
#   models/      - 데이터 모델
#   services/    - 비즈니스 로직
#   api/         - API 엔드포인트

## 제약사항 (constraints)
# 사용자가 수동으로 작성하세요.
# 예시:
# - no global state
# - no print() in production code (use logging)

## 테스트 설정 (test)
- test_command: {테스트 명령어}
- test_framework: {테스트 프레임워크}
- min_coverage: 80
- pre_commit: {true/false}

## 리팩토링 규칙 (refactor)
# 사용자가 수동으로 작성하세요.
# 예시:
# - max_file_lines: 300
# - max_function_lines: 30
# - max_class_methods: 10
```

---

### Step 10: 결과 출력

생성 완료 후 사용자에게 요약 출력:

```
## /init 완료

### 감지 결과
- 언어: {언어} {버전}
- 프레임워크: {프레임워크}
- 패키지 매니저: {매니저}
- 의존성: prod {N}개, dev {M}개
- 테스트: {프레임워크} ({명령어})
- 린터: {린터}
- 포매터: {포매터}

### 생성된 파일
- CLAUDE.md (프로젝트 루트)

### 수동 작성 필요 섹션
- 아키텍처 (architecture): 프로젝트 디렉토리 구조 설명
- 제약사항 (constraints): 금지 패턴 및 규칙
- 리팩토링 규칙 (refactor): 코드 크기 제한 등
```

---

## 주의사항

- 의존성 버전이 lockfile에 있으면 lockfile에서 정확한 버전을 읽는다
- 버전을 읽을 수 없으면 `>=` 또는 range 형식 그대로 표기한다
- 여러 언어가 혼재된 프로젝트는 모든 언어를 감지한다 (주 언어를 먼저 표시)
- 감지 실패한 항목은 `# (감지 실패 - 수동 작성 필요)` 표시
- 기존 CLAUDE.md가 있는데 덮어쓰기를 거부하면 아무것도 하지 않는다
