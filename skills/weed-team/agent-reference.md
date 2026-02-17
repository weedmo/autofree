# Full Agent Reference (27 agents)

| # | Agent | subagent_type | Model | Specialty |
|---|-------|---------------|-------|-----------|
| 1 | c-pro | c-pro | sonnet | C systems programming |
| 2 | code-reviewer | code-reviewer | opus | Code review, quality analysis |
| 3 | cpp-pro | cpp-pro | sonnet | Modern C++ patterns |
| 4 | data-engineer | data-engineer | sonnet | Data pipelines, ETL |
| 5 | data-scientist | data-scientist | sonnet | Statistical modeling, analytics |
| 6 | database-admin | database-admin | sonnet | DB operations, backup, replication |
| 7 | database-architect | database-architect | opus | DB design, data modeling |
| 8 | database-optimization | database-optimization | sonnet | DB performance optimization |
| 9 | database-optimizer | database-optimizer | sonnet | Query optimization, indexing |
| 10 | debugger | debugger | sonnet | Debugging, error analysis |
| 11 | deployment-engineer | deployment-engineer | sonnet | CI/CD, deployment automation |
| 12 | devops-troubleshooter | devops-troubleshooter | sonnet | Infrastructure troubleshooting |
| 13 | document-structure-analyzer | document-structure-analyzer | sonnet | Document structure, CLAUDE.md |
| 14 | error-detective | error-detective | sonnet | Log analysis, error patterns |
| 15 | mcp-expert | mcp-expert | sonnet | MCP integration |
| 16 | ml-engineer | ml-engineer | sonnet | ML pipelines, model serving |
| 17 | mlops-engineer | mlops-engineer | opus | MLOps infrastructure |
| 18 | network-engineer | network-engineer | sonnet | Network, DNS, SSL |
| 19 | nosql-specialist | nosql-specialist | sonnet | MongoDB, Redis, NoSQL |
| 20 | prompt-engineer | prompt-engineer | opus | Prompt optimization, LLM |
| 21 | python-pro | python-pro | sonnet | Python specialist |
| 22 | rust-pro | rust-pro | sonnet | Rust specialist |
| 23 | shell-scripting-pro | shell-scripting-pro | sonnet | Shell scripting, automation |
| 24 | sql-pro | sql-pro | sonnet | SQL queries, schema design |
| 25 | supabase-schema-architect | supabase-schema-architect | sonnet | Supabase DB design |
| 26 | test-engineer | test-engineer | sonnet | Test automation, QA |
| 27 | unused-code-cleaner | unused-code-cleaner | sonnet | Unused code cleanup |

## Special Agents

| Agent | subagent_type | Model | Usage |
|-------|---------------|-------|-------|
| Scout (Explore) | Explore | haiku | Phase 2 병렬 탐색 |
| Project Index | Explore | haiku | 프로젝트 인덱스 생성 |

## Core Agents (auto-spawned on team creation)

| Agent | Model |
|-------|-------|
| debugger | sonnet |
| test-engineer | sonnet |
| code-reviewer | opus |
| document-structure-analyzer | sonnet |
