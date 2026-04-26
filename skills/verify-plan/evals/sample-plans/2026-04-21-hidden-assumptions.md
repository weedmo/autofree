# Background Job Queue Implementation Plan

**Goal:** Replace the in-process job runner with a real queue so long-running tasks don't block the API.

**Architecture:** Use a job queue with Redis as the broker. Workers pull from the queue and write results to the database. The API enqueues jobs and clients poll a status endpoint.

**Tech Stack:** FastAPI, Redis, Postgres.

---

### Task 1: Add the queue library

**Files:**
- Modify: `pyproject.toml`

- [ ] Step 1: Add the queue library to dependencies.
- [ ] Step 2: Install with poetry.
- [ ] Step 3: Commit.

### Task 2: Create the job model

**Files:**
- Create: `backend/jobs/models.py`

- [ ] Step 1: Write a failing test for Job creation with status=pending.
- [ ] Step 2: Implement the Job model with id, status, payload, result, created_at, completed_at.
- [ ] Step 3: Run tests and confirm they pass.
- [ ] Step 4: Commit.

### Task 3: Build the worker

**Files:**
- Create: `backend/jobs/worker.py`

- [ ] Step 1: Write a failing test that runs a worker against a fake job and confirms the job ends up with status=completed.
- [ ] Step 2: Implement the worker loop that pulls from the queue, runs the handler, and updates job status.
- [ ] Step 3: Run tests.
- [ ] Step 4: Commit.

### Task 4: Wire up the enqueue endpoint

**Files:**
- Modify: `backend/api/jobs_router.py`

- [ ] Step 1: Write a failing test that POSTs to /jobs and asserts a 202 response with a job id.
- [ ] Step 2: Implement the POST /jobs endpoint that enqueues a job.
- [ ] Step 3: Implement the GET /jobs/{id} endpoint that returns status.
- [ ] Step 4: Run tests.
- [ ] Step 5: Commit.

### Task 5: Deploy

**Files:**
- Modify: `start.sh`

- [ ] Step 1: Add a worker process to start.sh so it runs alongside the API.
- [ ] Step 2: Commit.
