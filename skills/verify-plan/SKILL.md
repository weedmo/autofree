---
name: verify-plan
description: Use when an implementation plan markdown file has just been written or updated (especially under `docs/superpowers/plans/`, `docs/plans/`, or anywhere a plan-shaped document was just produced by writing-plans, brainstorming, or by hand) — runs a Codex ↔ Claude ↔ Codex three-pass verification loop that critiques AND directly edits the plan file in place until it is execution-ready. Trigger this whenever the user mentions "plan", "implementation plan", "verify the plan", "polish the plan", "make this plan bulletproof", or finishes drafting a plan, even if they don't explicitly say "verify". The skill is the primary mechanism for hardening a plan before execution and should not be skipped just because the plan looks reasonable.
---

# verify-plan

## What this skill is

A three-pass verification loop that turns a draft implementation plan into one a fresh engineer could execute without surprises. Two passes are run by Codex (`gpt-5.5`, `xhigh` reasoning, `--write` mode so it edits the plan file directly), and the middle pass is run by Claude as an independent reviewer who reads what Codex changed and pushes back on what it missed.

The plan file is mutated in place. There is no separate verdict document — the plan itself becomes the verdict, with a single metadata line appended to its header.

## Prerequisites (one-time)

This skill depends on the codex plugin's helper scripts and a few config tweaks. **First time only**, run:

```bash
bash "$(dirname "$(realpath "${BASH_SOURCE[0]:-$0}")")/../../skills/verify-plan/setup.sh"
```

Or equivalently, find this skill's directory and run `setup.sh` inside it. The setup script is idempotent — running it again does nothing if everything is already in place. It checks:

1. `codex` CLI is installed (instructs `npm install -g @openai/codex` if not).
2. `codex` plugin is installed in Claude Code (instructs `/plugin install codex@openai-codex` if not).
3. `~/.codex/config.toml` has `model = "gpt-5.5"`, `model_reasoning_effort = "xhigh"`, `service_tier = "fast"`, and `sandbox_mode = "danger-full-access"`. Missing entries are appended.
4. Codex auth status (instructs `codex login` if signed out).

If any check fails the script exits with a clear instruction. The skill itself will not run until all four pass.

## When to use

- Right after `superpowers:writing-plans` finishes producing a plan.
- Right after the user finishes hand-writing a plan and asks for a sanity check.
- When the user says any of: "verify this plan", "is this plan good", "tighten this plan", "make it bulletproof", "review the plan and fix it".
- When the bundled `Stop` hook (registered via `hooks/hooks.json`) fires because a plan-shaped markdown file was written or modified during the turn (a system-reminder will instruct you to invoke this skill on the listed paths).

If the file in question is *not* a plan (it's a spec, README, design doc, decision log, etc.), exit early with a one-line note. Do not run the loop on documents that are not implementation plans.

## Why this design

The single biggest failure mode of self-review is the reviewer agreeing with itself. By forcing one model (Codex) to make edits, then a second model (Claude) to read those edits and push back, then the first model again to reconcile, you get genuine friction instead of a rubber stamp. Each pass has a different *contract* — find-and-fix, dissent-and-augment, consistency-and-finalize — so they cannot collapse into "looks good to me".

Codex is given `--write` because critique without action is wasted time on a plan that needs to be ready-to-execute. Claude's middle pass is *also* given write authority — Claude should use `Edit` directly when it spots something Codex missed, not just list complaints.

## Locating the codex helper

Each codex pass invokes `codex-companion.mjs` from the installed codex plugin. Resolve the helper path dynamically — the codex plugin is versioned and its cache directory changes across updates:

```bash
CODEX_HELPER="$(find ~/.claude/plugins/cache/openai-codex -type f -name codex-companion.mjs 2>/dev/null | sort -V | tail -1)"
[[ -z "$CODEX_HELPER" ]] && { echo "codex plugin not installed — run /plugin install codex@openai-codex" >&2; exit 1; }
```

Use `$CODEX_HELPER` in the Pass 1 and Pass 3 Bash blocks below.

## Inputs

You need exactly one input: the **absolute path to the plan file**.

- If the user invokes the skill explicitly, ask them for the path if they didn't supply one.
- If the bundled Stop hook triggered the skill, the system-reminder will contain the path(s).
- Verify the file exists and is markdown before doing anything else.

## The loop

### Pass 0 — Setup (Claude, ~10s)

1. Read the plan file fully. If it is shorter than ~30 lines or does not contain task / step structure, it is probably not a real plan — abort with a one-line note.
2. Confirm the plan path is **inside the current working directory tree** (`pwd`). Codex's writable-roots default to the cwd; a plan outside that tree will silently fail to be edited. Abort with an instruction to run the skill from a directory that contains the plan.
3. Note the current git status of the plan file (untracked vs. tracked-and-clean vs. tracked-with-changes). You will mention this in the final summary so the user can `git diff` to see what the loop changed.
4. Resolve `$CODEX_HELPER` as shown above.
5. Announce to the user: `Running 3-pass verification on <path>. Pass 1 (Codex)...`

### Pass 1 — Codex find-and-fix (background, ~6–10 min typical)

Measured duration on Codex `gpt-5.5` at `xhigh` reasoning effort (n=1 per bucket, single run each):

| Input plan lines | Measured duration |
|---:|---|
| 139  | 6m01s |
| 409  | 6m00s |
| 989  | 10m01s |
| 3158 | 9m01s |

Two observations from the data: (1) there is a **~6-minute floor** — even tiny plans take roughly that long because xhigh reasoning + initial repo inspection have a fixed cost, and (2) duration correlates only weakly with plan size — plan structure and ambiguity matter more than line count. Outliers are possible: a 2000-line plan that triggered a `verifying`-phase stall ran past 13 minutes before being cancelled. **There is no upper bound** — see the polling rule below.

Submit a single Codex task in background mode. The prompt below is the exact contract — copy it verbatim with the path substituted.

```bash
node "$CODEX_HELPER" \
  task --background --write \
  --model gpt-5.5 --effort xhigh \
  "$(cat <<'PROMPT'
<task>
Critically review the implementation plan at PLAN_PATH and FIX every issue you find by editing the file directly. The goal is a no-mistakes plan that an engineer with zero project context can execute step by step.
</task>

<inspection_checklist>
- Vague or missing success criteria on any task or step
- File paths that look wrong or do not exist in the repo
- Steps that are too large (more than ~5 minutes of work) or trivially small
- Hidden assumptions about codebase state, conventions, available tools, or environment
- Missing failing-test step before implementation (TDD violation)
- Missing verification commands after each implementation step
- Skipped or unclear commit boundaries
- Unaddressed architectural risks, missing dependencies, or unstated prerequisites
- Inconsistent file paths, function names, or symbol names across tasks
- Missing rollback / undo guidance for risky steps
- Header (Goal / Architecture / Tech Stack) does not match the body
</inspection_checklist>

<action>
Edit the plan file directly to fix every issue you find. Do not ask for permission. Do not leave inline comments instead of edits — make the actual edits. Preserve the user's voice and structure; surgical fixes only.
</action>

<grounding_rules>
Only fix things you can verify against the plan text itself or against the project's actual file structure. If you must guess at intent, mark the corresponding output bullet with "(unverified)".
</grounding_rules>

<output_contract>
After editing, output exactly two sections, in this order, with no preamble:

## Fixed
- <one bullet per issue you actually fixed, with section or line reference>

## Remaining concerns
- <issues you flagged but did not fix, with reason>

Keep both sections under 30 lines total. If nothing needed fixing, say so explicitly in "## Fixed".
</output_contract>
PROMPT
)"
```

Replace `PLAN_PATH` in the heredoc with the real absolute path before piping into Bash. The companion will return a `task-...` job id immediately.

Then poll until completion using **exactly** `node "$CODEX_HELPER" status <jobId> --json`. Poll every 60 seconds — short enough to stay inside the 5-minute prompt-cache TTL, long enough that a typical 6–10 minute pass costs only 6–10 status calls instead of ~36–60 at the old 10s interval. The interval is uniform across plan sizes because the measured data shows duration does not scale linearly with plan size (a 23× size delta produced only a 1.7× duration delta, and the largest plan was *faster* than the next-largest). **Do NOT impose a time-based timeout.** Codex on a large plan legitimately runs for many minutes — aborting on a timer wastes the in-flight review and forces a restart. Keep polling until the job's `status` field becomes terminal (`completed`, `failed`, or `cancelled`):

- `completed` → proceed to result retrieval below.
- `failed` or `cancelled` → abort the loop, surface stderr/output verbatim, do not improvise. See "Failure handling".
- `queued` or `running` → keep waiting, no matter how long it has taken.

**CRITICAL — never use `status` without a jobId, and never use `status --all`.** Each `node codex-companion.mjs ...` invocation spins up a fresh broker instance; bare `status` / `status --all` only sees jobs that *this* invocation's broker observed (typically zero, since the submitting invocation already exited). It will report `No jobs recorded yet.` even when the job has long since completed, sending the polling loop into an infinite wait on an already-done job. **Always pass the explicit `<jobId>` you captured at submission**; that path is file-backed and reads correct cross-invocation state. If you ever see `No jobs recorded yet.` while polling, treat it as evidence you used the wrong command, not as evidence the job is stuck.

Parse the result as JSON and extract `.job.status`. If parsing fails, or the field is missing/empty, retry the same `status <jobId> --json` command once after a short pause; if it still fails, abort the loop and surface the raw output to the user — do NOT silently treat it as "still running".

For user visibility during long waits, print a one-line progress note at elapsed = 5min, 15min, 30min, then every 30min thereafter. Format: `Pass 1 still running — <elapsed>m elapsed, status=<status>, phase=<phase>`. This is informational only; it does not abort.

If the user wants to stop a runaway pass, they can run `node "$CODEX_HELPER" cancel <jobId>` themselves; the polling loop will then observe `cancelled` on the next tick and abort cleanly. Do not preemptively cancel on the user's behalf.

When the job is `completed`, retrieve the rendered output with `node "$CODEX_HELPER" result <jobId>`. Capture both:
- The "## Fixed" list (for the final summary).
- The "## Remaining concerns" list (this becomes Claude's starting point in Pass 2).

### Pass 2 — Claude dissent-and-augment (Claude, ~1–3 min)

Now you (Claude) take the wheel. Re-read the plan file *as it stands after Codex Pass 1* — Codex has edited it.

Your job is **not** to re-verify everything Codex already verified. Your job is to find what Codex missed or got wrong. Lean into disagreement: the value of this pass comes from being a different reader, not a confirming one.

Look hard at:

1. **Things that "look fine" but encode a hidden assumption.** A task that says "add the validator to the request handler" is fine only if there is exactly one obvious request handler. If there are five, the task is ambiguous and Codex probably missed it.
2. **Test plans that pass without proving anything.** A test like "assert response is 200" passes for many wrong reasons. Real verification requires asserting on the *behavior under test*.
3. **Glue and boilerplate that was assumed away.** Imports, configuration entries, route registrations, dependency injection wiring — Codex tends to leave these implicit. If the plan never mentions them, add a step.
4. **Cross-task ordering hazards.** Task 3 changing a function signature that Task 2's tests already lock in. Codex's per-task review usually doesn't catch this.
5. **The remaining concerns Codex listed.** For each one, decide: fix it yourself, escalate it to Codex Pass 3, or mark it as truly out of scope.

When you find an issue, **edit the plan file directly using the `Edit` tool**. Do not just write a list of things that should be fixed. The whole point of this pass is that you have authority to mutate the plan.

After editing, write a short bulleted "Pass 2 dissent" list in your working memory. This list goes into Pass 3's prompt. It should look like:

```
- Task 4 still doesn't say which migration runner to invoke; codex assumed `alembic upgrade head` but project uses `yoyo`. (I edited Task 4 to fix this.)
- Codex flagged "no rollback for the schema change" as a remaining concern; I left it for Pass 3 because it requires choosing between two approaches.
- Tasks 7 and 8 both modify the same selector; Task 8 will conflict with Task 7's edit. (Not yet fixed; for Pass 3.)
```

Empty list is acceptable only if you genuinely found nothing — don't pad it.

### Pass 3 — Codex consistency-and-finalize (background, ~30–90s)

Submit a second Codex task. This time the prompt carries Claude's dissent list as explicit input, and the contract shifts from find-and-fix to consistency-and-finalize.

```bash
node "$CODEX_HELPER" \
  task --background --write \
  --model gpt-5.5 --effort xhigh \
  "$(cat <<'PROMPT'
<task>
Re-verify the plan at PLAN_PATH for internal consistency and address the dissent items from a Claude reviewer below. You have already done one pass of edits on this plan; this is the final integrity pass before the plan is considered execution-ready.
</task>

<claude_dissent>
CLAUDE_DISSENT_BULLETS
</claude_dissent>

<consistency_checklist>
- Task numbering is sequential and complete; no gaps
- File paths in "Files:" headers match the actual edits referenced in the steps below them
- Symbol, function, and class names referenced across tasks are spelled identically
- Test names referenced from implementation steps actually appear in the test-writing steps
- Every "modify" reference to existing code is plausible given the file's real contents
- Architecture summary in the header still matches the body after edits
- Each Claude dissent item is either resolved by an edit or explicitly addressed in the verdict
</consistency_checklist>

<action>
Edit the plan file directly to resolve every dissent item and every consistency issue. If a dissent item is invalid or already handled, do not edit — address it in the verdict instead.
</action>

<output_contract>
After editing, output exactly two sections in this order, no preamble:

## Final fixes
- <bullets describing what you edited in this pass; reference dissent items by index when applicable>

## Verdict
- <PASS or NEEDS-WORK>
- If NEEDS-WORK: list the residual blocking issues, one per bullet.

Under 25 lines total.
</output_contract>
PROMPT
)"
```

`CLAUDE_DISSENT_BULLETS` is the bulleted list you wrote in Pass 2. If your list was empty, write `- (none — Claude review found nothing to escalate)`.

Poll the same way as Pass 1 (60s interval, status-based — wait until `completed`/`failed`/`cancelled`, no time-based cap, milestone progress notes at 5/15/30+ minutes). Capture the "## Final fixes" and "## Verdict" sections.

### Pass 4 — Stamp and report (Claude, ~10s)

1. Re-read the plan file one final time.
2. Insert a single verification metadata line **directly under the H1 header**, replacing any prior `> **Verified:**` line if one exists. Format:

   ```markdown
   > **Verified:** YYYY-MM-DDTHH:MMZ · Codex(gpt-5.5/xhigh) ↔ Claude · 2 codex passes + 1 claude pass · <PASS|NEEDS-WORK> · fixes=<count>
   ```

   - `fixes` count is the total number of bullets in Pass 1 "## Fixed" + Pass 2 dissent items you edited + Pass 3 "## Final fixes".
   - Use UTC.
   - This marker is what the bundled Stop hook checks; once it is present, the hook stays silent on future turns and will not re-trigger this skill on the same plan.

3. Report to the user. Format:

   ```
   verify-plan complete: <PASS|NEEDS-WORK>

   Pass 1 (Codex find-and-fix): <N> fixes
   Pass 2 (Claude dissent): <M> additional edits
   Pass 3 (Codex consistency): <K> final fixes

   Residual concerns: <none | bulleted list>

   Diff: git diff -- <plan_path>
   ```

   Do not paste the entire diff — the user can run the command themselves.

## Failure handling

- **Codex job duration is long**: this is NOT a failure. Long elapsed time alone never aborts the loop. The skill polls `node "$CODEX_HELPER" status <jobId>` indefinitely and only acts on the reported `status` field. While the job is `queued` or `running`, keep waiting. Surface progress notes at 5/15/30+ minute milestones for user visibility, but do not cancel. The user can manually run `node "$CODEX_HELPER" cancel <jobId>` if they decide to stop the run; the next poll tick will then observe `cancelled` and exit cleanly.
- **Codex job reports `failed` or `cancelled` status, or the helper exits non-zero**: abort the loop, tell the user which pass terminated and why, surface the helper's stderr / rendered output verbatim, leave the plan in whatever state Codex left it. Do not retry automatically. Do not improvise a Claude-only verification.
- **Codex completed but applied zero edits AND its rendered output mentions a sandbox / permission / writable-root / `bwrap` / `apply_patch` error**: this is a silent failure, not a real "nothing to fix". Treat it identically to a non-zero exit — abort the loop, surface the codex error verbatim, and do NOT promote Pass 2 (Claude) into find-and-fix to compensate. Pass 2 is a *dissent* pass; it must not run as a primary editor when Pass 1 never actually inspected the file. The risk this rule prevents: a user thinks they got a 3-pass verification when they actually got a single Claude pass, and the verdict line on the plan implies stronger validation than was performed.
- **Codex completed with zero edits AND its output gives a substantive "nothing to fix" rationale (no sandbox error)**: that is a legitimate clean Pass 1. Continue to Pass 2 normally; Pass 2 may still find dissent items.
- **Plan file is not a plan**: exit early with a one-line note and do nothing else.
- **`codex-companion.mjs` not found**: tell the user to run `/codex:setup` and `bash <skill>/setup.sh`. Do not try to call the codex CLI directly as a fallback.
- **Plan file is outside the codex CLI's writable roots** (typically the current working directory tree): codex will silently fail to edit. Detect this preemptively in Pass 0 — if the plan path is not under `pwd`, tell the user to move the plan into the project tree (or run the skill from a directory whose tree contains the plan) and abort before submitting any codex job. Do not "try and see" — the failure mode is a wasted background job and a misleading verdict.

## What this skill does NOT do

- It does not run the plan. Verification is upstream of execution.
- It does not create a separate verdict document. The plan file is the artifact.
- It does not refuse to edit a plan that is "already good enough". If you ran the loop, you commit to letting it edit. If the user wants a read-only review, they should not invoke this skill.
- It does not paraphrase Codex output. Codex's "## Fixed" / "## Final fixes" / "## Verdict" sections are surfaced verbatim in the final report.
