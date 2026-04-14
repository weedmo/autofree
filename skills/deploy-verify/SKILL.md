---
name: deploy-verify
description: "Post-deploy verification pipeline: land-and-deploy → canary → benchmark. Chains deploy and monitoring skills for safe production releases. Use /deploy-verify to merge PR and monitor, /deploy-verify canary for monitoring only."
---

# Deploy Verify — Post-Deploy Verification Pipeline

Orchestrates the deploy-to-production workflow with canary monitoring and performance checks.
Ensures safe releases with automated rollback signals.

## When to Use

- After `/ship` creates a PR and it's approved
- After manual merge to verify production health
- Performance regression check before/after deploy
- Ongoing production monitoring

## Modes

| Command | Mode | Skills Chain |
|---------|------|-------------|
| `/deploy-verify` | Full | land-and-deploy → canary → benchmark |
| `/deploy-verify canary <url>` | Monitor-only | canary (watch production) |
| `/deploy-verify perf <url>` | Performance | benchmark (before/after) |
| `/deploy-verify baseline <url>` | Baseline | benchmark --baseline |

## Prerequisites

Run `/setup-deploy` once per project to configure:
- Deploy platform (Fly.io, Render, Vercel, Netlify, Heroku, GitHub Actions, custom)
- Production URL
- Health check endpoints
- Deploy status commands

## Procedure

### Phase 1: Pre-deploy Baseline

Before merging, capture baselines:

1. Invoke `/benchmark <production-url> --baseline`:
   - Page load times (TTFB, FCP, LCP)
   - Core Web Vitals
   - Resource sizes (JS/CSS bundles)
   - Save to `.gstack/benchmark-reports/`

2. Invoke `/browse` for visual baseline:
   - Screenshots of key pages
   - Console error state

### Phase 2: Land and Deploy

Invoke `/land-and-deploy`:
1. Merge the PR
2. Wait for CI pipeline
3. Wait for deploy to complete
4. Initial health check (HTTP 200 on production URL)

If deploy fails → STOP, report to user with CI logs.

### Phase 3: Canary Monitoring

Invoke `/canary` immediately after deploy:
- Monitor for console errors (new errors vs baseline)
- Check page load failures
- Take periodic screenshots
- Compare against pre-deploy visual baseline
- Duration: 5 minutes default, configurable

**Alert triggers:**
| Signal | Threshold | Action |
|--------|-----------|--------|
| New console errors | Any | Alert user |
| Page load failure | Any | Alert + suggest rollback |
| Visual diff > threshold | >10% pixel diff | Alert user |
| Response time spike | >2x baseline | Alert user |

### Phase 4: Performance Comparison

After canary passes, invoke `/benchmark <production-url>`:
- Compare against Phase 1 baseline
- Flag regressions:
  - Timing >50% slower or >500ms increase → REGRESSION
  - Timing >20% slower → WARNING
  - Bundle size >10% larger → WARNING

### Phase 5: Health Dashboard

Invoke `/health` to verify code quality wasn't compromised:
- Run type checker, linter, tests
- Compare composite score with last known score
- Flag any degradation

### Phase 6: Final Report

Generate deploy verification report:

```markdown
## Deploy Verification: <branch-name>

### Status: ✅ HEALTHY / ⚠️ WARNINGS / ❌ ISSUES

### Deploy
- PR: #<number>
- Merged: <timestamp>
- Deploy completed: <timestamp>

### Canary (5 min)
- Console errors: 0 new
- Page failures: 0
- Visual diff: <X>% (threshold: 10%)

### Performance
- TTFB: <before>ms → <after>ms (<change>%)
- LCP: <before>ms → <after>ms (<change>%)
- Bundle: <before>KB → <after>KB (<change>%)

### Health Score: <before> → <after> / 10
```

### Phase 7: Learnings

Invoke `/learn` to save:
- Deploy duration for this platform
- Any issues encountered and their resolution
- Performance trends

## Escalation Rules

| Situation | Action |
|-----------|--------|
| Deploy fails | STOP, report CI logs |
| Canary detects new errors | Alert user, suggest rollback |
| Performance regression >50% | Alert user, suggest rollback |
| Health score dropped | Alert user with details |
| All checks pass | Report success, save learnings |

## Rollback Signal

This skill does NOT auto-rollback. It provides clear signals:
- **🟢 HEALTHY**: All checks pass
- **🟡 WARNING**: Minor regressions, user decides
- **🔴 CRITICAL**: Suggest immediate rollback, provide command
