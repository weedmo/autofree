# Dataset Filter API Implementation Plan

**Goal:** Add server-side filtering and sorting to the /datasets list endpoint so the frontend stops loading the entire table.

**Architecture:** Extend the existing list endpoint with query parameters for filter, sort, and pagination. Push filtering down to the SQL query rather than filtering in Python.

**Tech Stack:** FastAPI, SQLAlchemy, Postgres.

---

### Task 1: Add tests for filter parsing

**Files:**
- Create: `tests/datasets/test_filter_parser.py`

- [ ] Step 1: Write a failing test that parses `status=ready,size>1000` into a list of FilterClause objects.
- [ ] Step 2: Implement parse_filters(filter_str: str) -> list[FilterClause].
- [ ] Step 3: Run tests, confirm pass.
- [ ] Step 4: Commit.

### Task 2: Add tests for the list endpoint with filters

**Files:**
- Create: `tests/datasets/test_list_endpoint.py`

- [ ] Step 1: Write a failing test that calls GET /datasets?filter=status=ready and asserts only ready datasets are returned. The test calls list_datasets(filter=...) directly.
- [ ] Step 2: Implement list_datasets(filter: str | None = None) by passing filter into the underlying query builder.
- [ ] Step 3: Run tests, confirm pass.
- [ ] Step 4: Commit.

### Task 3: Refactor list_datasets to take a structured query object

**Files:**
- Modify: `backend/datasets/service.py`

- [ ] Step 1: Change the signature from list_datasets(filter: str | None = None) to list_datasets(query: DatasetListQuery). The DatasetListQuery dataclass holds parsed filter, sort, and pagination.
- [ ] Step 2: Update the only existing caller in `backend/api/datasets_router.py`.
- [ ] Step 3: Run tests.
- [ ] Step 4: Commit.

### Task 4: Add sort support

**Files:**
- Modify: `backend/datasets/service.py`

- [ ] Step 1: Write a failing test that calls list_datasets with a sort=created_at:desc and asserts ordering.
- [ ] Step 2: Implement sort handling inside list_datasets by appending order_by clauses.
- [ ] Step 3: Run tests.
- [ ] Step 4: Commit.

### Task 5: Add pagination

**Files:**
- Modify: `backend/datasets/service.py`

- [ ] Step 1: Write a failing test that calls list_datasets with limit=10, offset=20.
- [ ] Step 2: Implement pagination by adding limit/offset to the query.
- [ ] Step 3: Run tests.
- [ ] Step 4: Commit.
