---
name: autocode
description: "Autonomous code improvement loop — modify code, measure metrics, keep/discard, repeat. Inspired by Karpathy's autoresearch. /autocode init to setup, /autocode run to execute, /autocode status to review results, /autocode resume to continue interrupted experiments. Use when user wants to optimize code performance, reduce bundle size, improve throughput, or any measurable code improvement task."
---

# Autocode — Autonomous Code Improvement

Autonomous experiment loop for code improvement. Modify target code, measure metrics, keep improvements, discard regressions. Repeat indefinitely.

Inspired by [autoresearch](https://github.com/karpathy/autoresearch) — same pattern, generalized beyond ML training.

> **For ML-specific research** (model training, hyperparameter tuning, architecture experiments), use `/auto_research` instead. It includes deep-interview initialization, ML domain knowledge, and experiment categorization.

## Subcommands

| Command | Action | User Confirmation |
|---------|--------|-------------------|
| `/autocode init` | Interactive setup → generate `program.md` | Required |
| `/autocode run` | Execute experiment loop based on `program.md` | Not needed (autonomous) |
| `/autocode status` | Show `results.tsv` summary and progress | Not needed |
| `/autocode resume` | Resume interrupted experiment loop | Not needed |

## Procedure

### Step 0: Detect Project Root

```
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
AUTOCODE_DIR="$PROJECT_ROOT/.autocode"
PROGRAM_FILE="$AUTOCODE_DIR/program.md"
RESULTS_FILE="$AUTOCODE_DIR/results.tsv"
LOGS_DIR="$AUTOCODE_DIR/logs"
ANALYSIS_DIR="$AUTOCODE_DIR/analysis"
```

### Step 1: Parse Subcommand

- No args or `init` → **Init workflow** (Step 2)
- `run` → **Run workflow** (Step 3)
- `status` → **Status workflow** (Step 4)
- `resume` → **Resume workflow** (Step 5)

---

### Step 2: Init (`/autocode init`)

Interactive interview to generate a project-specific `program.md`.

#### 2A: Gather Information

Ask the user these questions (use `AskUserQuestion` for each):

1. **Target**: What file(s) should the agent modify?
   - Example: `src/parser.py`, `lib/engine.ts`
   - Recommend: single file or small module for best results

2. **Metric**: How do we measure success? (must be a single number, lower or higher is better)
   - Performance: `pytest-benchmark` output, request latency, throughput
   - Size: bundle size, binary size, memory usage
   - Quality: test count, lint warning count, type coverage %
   - Custom: any command that outputs a number

3. **Metric command**: The exact shell command to extract the metric number.
   - Example: `pytest --benchmark-only --benchmark-json=bench.json && python -c "import json; print(json.load(open('bench.json'))['benchmarks'][0]['stats']['mean'])"`
   - Example: `wc -c dist/bundle.js | awk '{print $1}'`
   - Example: `python run_bench.py | grep 'latency:' | awk '{print $2}'`

4. **Direction**: Is lower better or higher better?
   - `lower` = minimize (latency, bundle size, error count)
   - `higher` = maximize (throughput, test coverage, score)

5. **Guard command**: What must pass before we accept a change? (tests, lint, type check)
   - Example: `pytest && mypy src/`
   - Example: `npm test && npm run lint`
   - Can be empty if no guards needed

6. **Time budget per experiment** (optional, default: 2 minutes)
   - How long should each experiment run before timeout/kill?

#### 2B: Generate program.md

Create `$AUTOCODE_DIR/program.md` with the gathered information:

```markdown
# Autocode Program

## Target

- **Files to modify**: {target_files}
- **Read-only context**: {any files the agent should read but not modify}

## Metric

- **Command**: `{metric_command}`
- **Direction**: {lower|higher} is better
- **Name**: {metric_name} (e.g., "latency_ms", "bundle_bytes", "test_count")

## Guard

Before accepting any change, this must pass:
```
{guard_command}
```

## Constraints

- **Time budget**: {time_budget} per experiment
- **Do NOT**: {any restrictions — e.g., "don't change public API", "don't add dependencies"}

## Strategy hints

{Optional section — the user can add hints about what to try}
- Example: "try replacing the regex parser with a state machine"
- Example: "experiment with different data structures for the cache"
```

Also initialize `$AUTOCODE_DIR/results.tsv` with header:

```
commit	metric	status	description	delta
```

Create `$AUTOCODE_DIR/logs/` directory for experiment logs.
Create `$AUTOCODE_DIR/analysis/` directory for periodic analysis reports.

Add `.autocode/` to `.gitignore` if not already there (ask user first).

Present the generated program.md via `AskUserQuestion` with options:
[Approve and save] [Edit and regenerate] [Start over]

---

### Step 3: Run (`/autocode run`)

#### 3A: Pre-flight checks

1. Verify `$PROGRAM_FILE` exists. If not: `program.md가 없습니다. /autocode init을 먼저 실행하세요.`
2. Read `$PROGRAM_FILE` to load configuration.
3. Verify target files exist.
4. Verify guard command passes on current code.
5. Create experiment branch: `git checkout -b autocode/{date}` from current branch.

#### 3B: Execution mode selection

Ask the user (via AskUserQuestion):

> How should experiments run?
>
> 1. **Single agent** — One experiment at a time, sequential. Simple and reliable.
> 2. **Single agent + periodic analysis** — Sequential experiments, but every 10 experiments
>    a background analyst agent reviews trends and adjusts strategy.

Store the chosen mode in `$AUTOCODE_DIR/mode.txt` (`single` or `hybrid`).

#### 3C: Establish baseline

1. Run the metric command on unmodified code.
2. Validate metric output is a finite number. If parsing fails, abort with error.
3. Record baseline in `results.tsv`.
4. Display:
   ```
   Baseline established:
   - {metric_name}: {baseline_value}
   - Branch: autocode/{date}
   - Mode: {single|hybrid}
   - Starting experiment loop...
   ```

#### 3D: Experiment loop (Single Agent)

**LOOP FOREVER** (until user interrupts):

1. **Plan**: Analyze target code. Think of an improvement idea.

   **Strategy progression:**

   **Early experiments (1-10)**: Systematic exploration
   - Start with the highest-impact area from strategy hints (if any)
   - Try: algorithmic improvements, data structure changes, removing unnecessary work,
     simplification, caching, batching, loop optimization
   - Review previous experiments in `results.tsv` to avoid repeating failed ideas

   **Mid experiments (11-30)**: Focused exploitation
   - Double down on directions that showed improvement
   - Try combinations of successful changes
   - Look for patterns in what worked vs what didn't

   **Late experiments (30+)**: Creative exploration
   - Try more radical architectural changes
   - Revisit discarded ideas with modifications
   - Try the opposite of what's been working

   **When stuck** (3+ consecutive discards):
   - Re-read the target code for new angles
   - Try combining previous near-misses
   - Switch to a completely different approach
   - Try the opposite of what you've been trying

2. **Modify**: Edit the target file(s) with the experimental change.
   - Keep changes focused — one idea per experiment.
   - Follow existing code style.

3. **Commit**: `git add {target_files} && git commit -m "experiment: {short description}"`

4. **Guard**: Run the guard command.
   - If it fails → this is a bug in the change. Attempt a quick fix (max 2 tries).
   - If still failing → log as `crash`, revert, move on.

5. **Measure**: Run the metric command, redirect output to log.
   - `{metric_command} > $LOGS_DIR/exp_{N}.log 2>&1`
   - Do NOT let output flood context — extract only the metric value.
   - Validate metric is a finite number. If NaN, empty, or non-numeric → treat as crash
     with description "metric extraction failed: {raw_output}".
   - If the command fails or times out → log as `crash`, revert, move on.

6. **Decide**:
   - **Improved** (metric better than current best):
     - Calculate delta: `((new - best) / best) * 100`
     - Log as `keep` in results.tsv with delta
     - Print: `KEEP: {description} — {metric_name}: {old} → {new} ({delta}%)`
     - This becomes the new baseline to beat
   - **Equal or worse**:
     - Log as `discard` in results.tsv with delta
     - Print: `DISCARD: {description} — {metric_name}: {value} (best: {best})`
     - `git reset --hard HEAD~1` to revert
   - **Crash**:
     - Log as `crash` in results.tsv
     - Print: `CRASH: {description} — {error_summary}`
     - `git reset --hard HEAD~1` to revert

7. **Continue**: Go to step 1. Do NOT ask the user. Do NOT stop.

#### 3E: Experiment loop (Single Agent + Periodic Analysis — Hybrid Mode)

Same as 3D single-agent loop, but every 10 experiments, spawn a background Analyst agent:

```
Agent(
  description="Analyze autocode experiment results",
  subagent_type="data-scientist",
  prompt="Read $RESULTS_FILE and logs in $LOGS_DIR/. Analyze:
    1. Which experiment approaches yield the most improvement
    2. Diminishing returns in any direction
    3. Patterns in what works vs what fails
    4. Suggested next experiments based on trends
    Write analysis to $ANALYSIS_DIR/analysis_{N}.md",
  run_in_background=true
)
```

**Non-blocking**: The experiment loop does NOT pause while the analyst runs — it continues experimenting.

**Feedback integration**: When the analyst completes (analysis file appears), the main loop reads its
analysis before the next experiment and adjusts strategy accordingly. Specifically:
- If the analyst identifies a promising direction → prioritize experiments in that direction
- If the analyst flags diminishing returns → switch to a different approach
- If the analyst spots a pattern in crashes → avoid similar changes

**Analysis trigger**: The counter resets after each analysis. If the analyst is still running when
the next 10-experiment boundary is reached, skip spawning another one — wait for the current analyst to finish.

#### 3F: Simplicity criterion

All else being equal, simpler is better:
- A tiny improvement that adds ugly complexity → probably not worth it
- An improvement from deleting code → definitely keep
- Equal metric but simpler code → keep

#### 3G: Timeout handling

If an experiment exceeds the time budget:
- Kill the process
- Treat as `crash`
- Revert and move on

#### 3H: Never stop

Once the loop begins, do NOT pause to ask "should I continue?". The user may be away.
Keep experimenting until manually interrupted. If you run out of ideas:
- Re-read the target code for new angles
- Try combining previous near-misses
- Try more radical architectural changes
- Try the opposite of what you've been trying
- In hybrid mode, re-read the latest analysis for overlooked suggestions

---

### Step 4: Status (`/autocode status`)

1. If `$RESULTS_FILE` doesn't exist: `아직 실험 결과가 없습니다. /autocode init 후 /autocode run을 실행하세요.`

2. Read and parse `results.tsv`.

3. Display summary:

```
## Autocode Status

**Branch**: autocode/{date}
**Experiments**: {total} total ({kept} kept, {discarded} discarded, {crashed} crashed)
**Best metric**: {best_value} (baseline: {baseline_value}, improvement: {pct}%)
**Current best commit**: {commit_hash}

### Experiment History
| # | Commit | Metric | Status | Description | Delta |
|---|--------|--------|--------|-------------|-------|
| 1 | a1b2c3d | 145.3 | keep | baseline | — |
| 2 | b2c3d4e | 132.1 | keep | replace linear search with binary search | -9.1% |
| 3 | c3d4e5f | 138.7 | discard | add memoization cache | +5.0% |
| 4 | d4e5f6g | 0.0 | crash | restructure main loop (TypeError) | — |
| 5 | e5f6g7h | 128.9 | keep | eliminate redundant copies | -2.4% |

### Kept Changes (cumulative)
1. replace linear search with binary search (-9.1%)
2. eliminate redundant copies (-2.4%)

Total improvement: -11.3% from baseline
```

4. If experiments are currently running, also show:
   - Time elapsed since loop started
   - Estimated experiments per hour

---

### Step 5: Resume (`/autocode resume`)

1. Verify `$PROGRAM_FILE` and `$RESULTS_FILE` exist.
   If not: `실험 데이터가 없습니다. /autocode init 후 /autocode run을 먼저 실행하세요.`
2. Read the last state from results.tsv.
3. Detect the experiment branch and verify it's checked out.
4. Find the current best metric from results.
5. Read execution mode from `$AUTOCODE_DIR/mode.txt` (default: `single` if missing).
6. Display:
   ```
   Resuming autocode:
   - Branch: autocode/{date}
   - Experiments completed: {N}
   - Current best: {metric_name}: {value}
   - Mode: {single|hybrid}
   - Last experiment: {description} ({status})
   - Resuming experiment loop...
   ```
7. Continue the experiment loop (3D or 3E based on mode) from where it left off.

---

## Tool Usage

| Phase | Tool | Purpose |
|-------|------|---------|
| Init questions | `AskUserQuestion` | Gather target, metric, guard, constraints |
| Init confirmation | `AskUserQuestion` | Approve/edit program.md |
| Mode selection | `AskUserQuestion` | Choose single or hybrid execution mode |
| Code analysis | `Read`, `Grep`, `Glob` | Analyze target files before proposing experiments |
| Code modification | `Edit` | Modify target files with experimental changes |
| Running experiments | `Bash` | Execute metric/guard commands (redirect output to logs) |
| Metric extraction | `Bash` | Extract and validate metric from log files |
| Results logging | `Edit` or `Bash` | Append to results.tsv |
| Periodic analysis | `Agent(subagent_type="data-scientist", run_in_background=true)` | Hybrid mode: analyze trends every 10 experiments |
| Analysis reading | `Read` | Read analyst output to adjust strategy |

## Key Principles

- **Single measurable metric** — the core requirement. No metric = no autocode.
- **Guard before accept** — tests/lint must pass. Never keep broken code.
- **Git as checkpoint** — every experiment is a commit. Easy to review, revert, cherry-pick.
- **Simplicity criterion** — complexity cost must be weighed against improvement magnitude.
- **Never stop** — autonomous loop runs until interrupted.
- **Adaptive strategy** — shift from systematic exploration to focused exploitation based on results.
- **Hybrid mode** — periodic background analysis improves strategy without blocking the experiment loop.
- **Redirect output** — never let experiment output flood the context window. Log to files, extract metrics via grep.
- **Validate metrics** — always check that extracted metrics are finite numbers before comparing.
- **program.md is portable** — can be used with any AI agent, not just Claude Code.
- **results.tsv is the log** — untracked by git, append-only record of all experiments.
- **.autocode/ is ephemeral** — gitignored, project-local, disposable.
