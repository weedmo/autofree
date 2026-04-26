# JWT Refresh Token Implementation Plan

**Goal:** Add refresh-token rotation to the existing FastAPI auth service so access tokens expire in 15 minutes and clients can refresh without re-login.

**Architecture:** Store refresh tokens in Redis keyed by user id. On refresh, issue a new access+refresh pair and delete the old refresh token (rotation). Reuse of an old refresh token revokes the entire chain.

**Tech Stack:** FastAPI, Redis, PyJWT.

---

### Task 1: Add Redis client

**Files:**
- Create: `backend/auth/redis_client.py`

- [ ] Step 1: Create the redis client module with a get_client() function.
- [ ] Step 2: Add a connection check that pings on startup.
- [ ] Step 3: Done.

### Task 2: Implement refresh token issuance

**Files:**
- Modify: `backend/auth/jwt_handler.py`

- [ ] Step 1: Add issue_refresh_token() that generates a uuid4, stores it in redis with the user id, and returns the token.
- [ ] Step 2: Add a /auth/refresh endpoint that accepts the old refresh token, validates it, deletes it, and issues a new access+refresh pair. Also handle reuse detection by checking if the token was already deleted, and if so, revoke all tokens for that user. Make sure to set the access token TTL to 15 minutes and the refresh token TTL to 7 days. The endpoint should return both tokens in the response body. Add proper error handling for expired tokens, invalid tokens, and reused tokens.

### Task 3: Update login endpoint

**Files:**
- Modify: `backend/auth/login.py`

- [ ] Step 1: Update the login endpoint to issue both an access token and a refresh token.
- [ ] Step 2: Commit.

### Task 4: Add tests

**Files:**
- Create: `tests/auth/test_refresh.py`

- [ ] Step 1: Write tests for the refresh flow, reuse detection, and token expiration.
- [ ] Step 2: Run pytest.
