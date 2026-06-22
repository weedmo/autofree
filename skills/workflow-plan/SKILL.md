---
name: workflow-plan
description: >-
  Author an implementation plan that is shaped to run on the Claude Code Workflow
  orchestration tool — decomposed into phases, with each unit of work tagged as a
  single agent, a parallel fan-out, a pipeline, a barrier, or a verification pass,
  and written to a markdown file. Use this when you want a plan that translates
  directly into a Workflow script (phase/agent/parallel/pipeline), when you're
  about to orchestrate multi-agent work and need the structure decided first, or
  whenever someone says "workflow plan", "plan for a workflow", or "워크플로우에 맞게
  플랜 짜줘". Invoke explicitly via /workflow-plan.
---

# Workflow Plan

Write an implementation plan whose structure maps **one-to-one** onto the Claude Code
`Workflow` orchestration tool. A normal plan lists steps. A workflow plan additionally
decides, for every chunk of work, *how it executes* — one agent, a parallel fan-out, a
pipeline, a barrier, or a verification pass — so that turning the plan into a runnable
`Workflow` script is mechanical rather than a fresh design problem.

The whole point: the hard part of orchestration is not writing the JS, it's deciding the
shape (what fans out, what must wait for everything, what verifies what). This skill front-
loads that decision into the plan, so execution becomes translation.

## When the shape matters

Before writing anything, internalize the handful of primitives the plan has to target. These
are the Workflow tool's building blocks, and every phase of the plan should resolve to one of
them.

- **`phase(title)`** — a named group of work. Plans become phases. Use phases to model the
  natural arc of the task (e.g. understand → design → implement → review), not to micro-split.
- **`agent(prompt, opts)`** — one subagent. Returns its text, or a validated object when given
  a `schema`. Reach for a schema whenever a later phase consumes the result as data rather than
  prose — it removes parsing and forces the agent to return clean fields.
- **`pipeline(items, stage1, stage2, …)`** — **the default for any multi-stage work.** Each item
  flows through all stages independently with *no barrier between stages*: item A can be in stage 3
  while item B is still in stage 1. Wall-clock is the slowest single chain, not the sum of stages.
- **`parallel(thunks)`** — a **barrier**: it waits for everything before returning. Only correct when
  the next step genuinely needs *all* prior results at once (dedup/merge across the full set, an
  early-exit on total count, or a prompt that compares items against each other).
- **`isolation: 'worktree'`** — give an agent its own git worktree. Needed only when agents mutate
  files in parallel and would otherwise collide. It costs setup time and disk, so don't default to it.

The single most common mistake is reaching for a barrier (`parallel` between stages) when a
`pipeline` would do. If your reason is "I need to flatten/map/filter the results first," that is
*not* a barrier — do the transform inside a pipeline stage. A barrier is justified only by a real
cross-item dependency. Bake this bias into the plan: **pipeline by default, barrier only with a
named reason.**

## What the plan must decide for every phase

For each phase, the plan answers these so the executor never has to guess:

1. **Intent** — what this phase produces, in one line.
2. **Work-list** — what are the items being fanned out over? Are they known up front, or must an
   earlier step *scout* them first (list the files, find the call sites, scope the diff)? Scouting
   is itself a phase; name it. A fan-out over an unknown work-list is a bug.
3. **Shape** — which primitive: single `agent`, parallel fan-out, `pipeline`, loop-until-condition,
   or a verification pass. State it explicitly.
4. **Per-unit task** — the prompt each agent runs, at least in summary.
5. **Structured output** — if downstream consumes this as data, sketch the schema fields. If it's
   prose for a human, say so.
6. **Barrier?** — yes/no, and if yes, the cross-item reason (dedup, merge, early-exit, cross-compare).
   Default no.
7. **Isolation?** — worktree only if this phase mutates files in parallel.
8. **Depends on** — which earlier phase's output feeds this one. This is what makes the phases a graph
   rather than a list.

## Verification is a first-class phase, not an afterthought

Workflows get their reliability from *checking their own output*. When the task warrants it (reviews,
audits, anything where a wrong answer is costly), the plan should include a verification phase and pick
a pattern that fits:

- **Adversarial verify** — spawn N skeptics per finding, each prompted to *refute* it; keep only what
  survives a majority. Stops plausible-but-wrong results.
- **Perspective-diverse verify** — when a result can fail in different ways, give each verifier a
  distinct lens (correctness, security, repro) instead of N identical ones.
- **Judge panel** — generate several independent attempts, score them, synthesize from the winner.
- **Loop-until-dry** — for unknown-size discovery, keep spawning finders until K rounds turn up nothing
  new; dedup against everything seen so far, not just what was kept.
- **Completeness critic** — a final agent asking "what's missing?" whose findings seed another round.

Scale the verification to the task. "Quick plan to add a flag" needs none. "Audit this for security
bugs" wants an adversarial pass. Say which, and why.

## Output

Write the plan to a markdown file. Default location `docs/plans/<slug>.md` — if the repo already keeps
plans somewhere (`.omc/plans/`, `docs/plans/`, an existing convention), follow it. Confirm the path with
the user if it's ambiguous, then write the file and report where it landed.

Use this structure:

```markdown
# Plan: <title>

## Goal
<one short paragraph: what done looks like>

## Success criteria
- [ ] <verifiable outcome — a test passes, a file exists, output matches>
- [ ] ...

## Constraints / non-goals
- <what's out of scope, what must not break>

## Execution shape
<2-4 sentences: the phases and how they map onto Workflow primitives. The bird's-eye view
someone reads before the per-phase detail.>

## Phases

### Phase 1 — <name>   `phase('<name>')`
- **Intent:** ...
- **Work-list:** <known up front | scouted by Phase 0>
- **Shape:** <single agent | parallel fan-out | pipeline(stageA→stageB) | loop-until-dry>
- **Per-unit task:** ...
- **Structured output:** <schema fields, or "prose">
- **Barrier?:** <no | yes — reason>
- **Isolation?:** <no | worktree — reason>
- **Depends on:** <— | Phase N output>

### Phase 2 — <name>   `phase('<name>')`
...

## Verification
<the pattern chosen and why, or "none — low-risk change">

## Workflow skeleton
```js
// A runnable sketch, not the final script — enough that execution is translation.
phase('<name>')
const items = await agent('scout the work-list', { schema: ... })
const results = await pipeline(items.list,
  item => agent(`do X to ${item}`, { phase: '<name>', schema: ... }),
  review => parallel(review.findings.map(f => () => agent(`verify ${f}`, { phase: 'Verify' }))),
)
return results.flat().filter(Boolean)
```
```

The skeleton at the end is what closes the loop — it proves the phases above actually compose into a
script. Keep it honest: if a phase can't be expressed cleanly in the skeleton, the phase isn't fully
designed yet. Go back and fix the plan, not the skeleton.

## How to work

1. Understand the task well enough to name its natural phases. If the request is broad, scout the
   codebase first (or say the workflow's first phase must scout) — don't fan out over an unknown work-list.
2. For each phase, fill in the eight decisions above. Be decisive about shape; "maybe parallel" helps no one.
3. Default every multi-stage phase to `pipeline`. Promote to a barrier only when you can name the
   cross-item dependency.
4. Add a verification phase sized to the risk.
5. Write the skeleton and sanity-check that the phases compose. Fix the plan if they don't.
6. Save the markdown file and tell the user the path.
