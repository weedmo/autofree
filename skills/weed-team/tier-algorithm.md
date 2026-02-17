# 4-Tier Agent Selection Algorithm

Apply tiers in order. Duplicates are removed.

## Tier 0 - Default (always included, 4 agents)

| Agent | Role |
|-------|------|
| debugger | Debugging specialist |
| test-engineer | Test automation |
| code-reviewer | Code review |
| document-structure-analyzer | CLAUDE.md maintenance |

## Tier 1 - Language Mapping

Detect from `language` field in CLAUDE.md. If multiple languages, add **all** matching.

| Language Keyword | Agent |
|-----------------|-------|
| Python, python | python-pro |
| Rust, rust | rust-pro |
| C++, cpp, c++ | cpp-pro |
| C (standalone), c (standalone) | c-pro |
| Shell, Bash, shell, bash | shell-scripting-pro |

**Note:** "C" must be distinguished from "C++". If "C/C++", add both.

## Tier 2 - Stack Mapping (dependency/tool keywords)

Match in `dependencies` (prod+dev) and `toolchain`. **Case-insensitive**, match if keyword is **contained** in package name.

| Category | Dependency Keywords | Agents |
|----------|-------------------|--------|
| ML/AI | torch, tensorflow, transformers, scikit-learn, huggingface, jax, onnx, accelerate | ml-engineer, data-scientist |
| MLOps | mlflow, wandb, dvc, bentoml, kubeflow, sagemaker | mlops-engineer |
| Data Pipeline | airflow, prefect, dagster, dbt, spark, kafka, pandas, polars, dask | data-engineer |
| SQL DB | sqlalchemy, psycopg2, asyncpg, alembic, prisma, diesel, sqlx, duckdb | sql-pro, database-architect |
| Supabase | supabase | supabase-schema-architect |
| NoSQL | mongodb, pymongo, redis, elasticsearch, cassandra, neo4j | nosql-specialist |
| Infra | docker, kubernetes, helm, terraform | deployment-engineer |
| DevOps | ansible, pulumi, cloudformation | devops-troubleshooter |
| Network | grpc, protobuf, ros2, rclpy, websocket | network-engineer |
| MCP | mcp, model-context-protocol | mcp-expert |
| LLM | openai, anthropic, langchain, llama-index, llama_index, vllm | prompt-engineer |
| Shell | Makefile, pre_commit: true, .github/workflows | shell-scripting-pro |

**Additional Infra/Shell rules:**
- Also detect `Docker`, `CI`, `Makefile`, `pre_commit` in `toolchain` section
- If `ci: GitHub Actions` or `ci: GitLab CI` → add `deployment-engineer`

## Tier 3 - Task Keyword Mapping

Match in `task_description`. Detect **both Korean and English**. Skip if no task description.

| Task Keywords (Korean / English) | Agents |
|--------------------------------|--------|
| data pipeline, ETL, pipeline | data-engineer |
| deploy, CI/CD, release | deployment-engineer |
| machine learning, ML, model, training, inference | ml-engineer, data-scientist |
| database, DB, schema, migration | database-architect, sql-pro |
| network, DNS, SSL, load balancer | network-engineer |
| documentation, docs | document-structure-analyzer |
| prompt, LLM, AI feature | prompt-engineer |
| infrastructure, docker, kubernetes | devops-troubleshooter, deployment-engineer |
| unused, dead code, cleanup | unused-code-cleaner |
| error, log, debug | error-detective |
| performance, optimize | database-optimizer (only for DB projects) |
| DB ops, backup, replication, monitoring | database-admin |
| DB performance, query optimization, index | database-optimizer, database-optimization |

**DB project detection:** If any agent from SQL DB, Supabase, or NoSQL matched in Tier 2 → project is DB-related.
