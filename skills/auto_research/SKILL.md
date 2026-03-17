---
name: auto_research
description: "Autonomous ML research loop with deep-interview initialization. Analyzes ML repos, designs experiments, modifies training code, measures metrics, keeps improvements, discards regressions. Use /auto_research when user wants to run autonomous ML experiments, optimize model training, tune hyperparameters, improve model architecture, or do any ML research automation. Also triggers on 'research loop', 'experiment loop', 'overnight training', 'autonomous ML', or 'auto experiment'."
argument-hint: "<subcommand: init|run|status|analyze|resume>"
---

# Auto Research — Autonomous ML Research

Autonomous experiment loop for ML research. Analyze an ML repository, design experiments informed by
domain knowledge, modify training code, measure metrics, keep improvements, discard regressions. Repeat
indefinitely.

Inspired by [Karpathy's autoresearch](https://github.com/karpathy/autoresearch) — specialized for ML
research with deep-interview initialization and adaptive experiment strategy.

## Subcommands

| Command | Action | User Confirmation |
|---------|--------|-------------------|
| `/auto_research init` | Deep-interview → generate `research_program.md` | Required (interview) |
| `/auto_research run` | Execute experiment loop (single or multi-agent) | Execution mode selection |
| `/auto_research status` | Show `results.tsv` summary and progress | Not needed |
| `/auto_research analyze` | Deep analysis of experiment trends and insights | Not needed |
| `/auto_research resume` | Resume interrupted experiment loop | Not needed |

## Procedure

### Step 0: Detect Project Root

```
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
RESEARCH_DIR="$PROJECT_ROOT/.auto_research"
PROGRAM_FILE="$RESEARCH_DIR/research_program.md"
RESULTS_FILE="$RESEARCH_DIR/results.tsv"
LOGS_DIR="$RESEARCH_DIR/logs"
```

### Step 1: Parse Subcommand

- No args or `init` → **Init workflow** (Step 2)
- `run` → **Run workflow** (Step 3)
- `status` → **Status workflow** (Step 4)
- `analyze` → **Analyze workflow** (Step 5)
- `resume` → **Resume workflow** (Step 6)

---

### Step 2: Init — Deep Interview (`/auto_research init`)

The init phase uses a Socratic deep-interview process to thoroughly understand the ML project
and research goals before generating a research program. This prevents wasted experiments from
vague or misunderstood objectives.

#### Phase 2A: Repository Reconnaissance

Before asking the user anything, scan the repo to gather facts autonomously:

1. **Detect ML framework**: PyTorch, TensorFlow, JAX, HuggingFace, Lightning, etc.
2. **Identify key files**:
   - Training scripts (train.py, main.py, run_*.py, etc.)
   - Model definitions (model.py, architecture files)
   - Config files (config.yaml, hparams.yaml, hydra configs)
   - Data pipeline (dataset.py, dataloader, prepare.py)
   - Evaluation scripts (eval.py, test.py, benchmark scripts)
3. **Extract current metrics**: Look for logged metrics, wandb/tensorboard configs, evaluation functions
4. **Detect constraints**: GPU requirements, dependencies, data paths, environment setup
5. **Read README and docs**: Understand the project's purpose and structure

Store findings as `recon_context`. This prevents asking the user questions the code already answers.

#### Phase 2B: Deep Interview Loop

Initialize interview state and persist to `$RESEARCH_DIR/interview_state.json`:

```json
{
  "interview_id": "<uuid>",
  "type": "ml_research",
  "initial_recon": "<recon_context summary>",
  "rounds": [],
  "current_ambiguity": 1.0,
  "threshold": 0.2,
  "challenge_modes_used": []
}
```

Update this file after every round so interrupted interviews can resume.
If `$RESEARCH_DIR/interview_state.json` exists when `init` is invoked, ask:
"Previous interview found ({N} rounds, ambiguity {score}%). Resume or restart?"

Announce:

> Starting research interview. I've scanned your repo and found: {recon_summary}.
> I'll ask targeted questions to define the research program. Ambiguity: 100%

**Clarity Dimensions for ML Research** (weighted scoring):

| Dimension | Weight | What it measures |
|-----------|--------|-----------------|
| Research Goal | 0.30 | What metric to optimize, what constitutes success |
| Experiment Scope | 0.25 | Which files to modify, what's off-limits |
| Evaluation Protocol | 0.25 | How to measure, baseline, comparison method |
| Resource Constraints | 0.20 | GPU budget, time per experiment, VRAM limits, dependencies |

**Ambiguity formula:**
`ambiguity = 1 - (goal × 0.30 + scope × 0.25 + evaluation × 0.25 + resources × 0.20)`

**Interview question strategy by dimension:**

| Dimension | Question Style | Example |
|-----------|---------------|---------|
| Research Goal | "What specific improvement?" | "You want lower val_loss — is that on the existing eval set, or do you have a specific benchmark?" |
| Experiment Scope | "What can change?" | "I see train.py has the model and optimizer. Should I also experiment with the data augmentation in dataset.py?" |
| Evaluation Protocol | "How do we know it works?" | "The training script prints loss but no held-out eval. Should I add a validation step, or is training loss sufficient?" |
| Resource Constraints | "What are the limits?" | "I detected an RTX 4090 (24GB). Should I stay within current VRAM usage, or is some increase acceptable for better metrics?" |

**Rules:**
- Ask ONE question per round via `AskUserQuestion`, targeting the weakest dimension
- Use recon_context to ask informed questions — never ask what the code reveals
- Score ambiguity after every answer using a structured scoring prompt (see below), display transparently
- Proceed to spec generation when ambiguity ≤ 0.2
- **Round 4+**: Allow early exit if user says "enough", "let's go", "start experimenting" — show current ambiguity and unclear dimensions, confirm before proceeding
- Soft warning at round 8, hard cap at round 15

**Ambiguity scoring prompt** (use after each answer):
```
Given this ML research interview transcript, score clarity on each dimension (0.0-1.0):

Original idea: {idea}
Repo recon: {recon_summary}
Transcript: {all rounds Q&A}

Score each:
1. Research Goal (0.0-1.0): Is the optimization target unambiguous?
2. Experiment Scope (0.0-1.0): Are editable vs read-only files clear?
3. Evaluation Protocol (0.0-1.0): Could you write the metric extraction command?
4. Resource Constraints (0.0-1.0): Are GPU/VRAM/time/dependency limits clear?

For each: score, justification (one sentence), gap (what's still unclear if < 0.9).
Respond as JSON.
```

**Challenge modes** (used once each):
- **Round 4+: Contrarian** — "Do you actually need to change the architecture, or could a learning rate sweep get you 80% of the way?"
- **Round 6+: Simplifier** — "What's the minimum viable experiment that would tell you if this research direction is worth pursuing?"

#### Phase 2C: Generate research_program.md

When ambiguity ≤ threshold, crystallize the interview into a research program:

```markdown
# Auto Research Program

## Metadata
- Interview ID: {uuid}
- Final Ambiguity: {score}%
- Generated: {timestamp}
- ML Framework: {framework}

## Research Goal
- **Primary metric**: {metric_name} (e.g., val_bpb, val_accuracy, mAP)
- **Direction**: {lower|higher} is better
- **Success threshold**: {target value, if any}
- **Secondary metrics**: {optional — e.g., VRAM, throughput, inference latency}

## Experiment Scope
- **Files to modify**: {editable files}
- **Read-only context**: {files to read but not modify}
- **Off-limits**: {files/modules that must not be changed}

## Evaluation Protocol
- **Metric command**: `{command to extract primary metric}`
- **Resource command**: `{command to extract VRAM/time/etc}`
- **Guard command**: `{tests/checks that must pass}`
- **Time budget**: {minutes per experiment}
- **Baseline**: {to be established on first run}

## Resource Constraints
- **GPU**: {detected or specified}
- **VRAM policy**: {strict limit | soft limit with threshold | no limit}
- **Dependency policy**: {no new deps | allow with user approval}
- **Max concurrent experiments**: {1 for single-agent, N for multi-agent}

## Strategy
- **Priority areas**: {what to try first, from interview}
- **Hints**: {user-provided strategy hints}
- **Avoid**: {explicitly excluded approaches}

## Experiment Taxonomy
Categorize experiments for systematic exploration:
1. **Hyperparameter tuning** — LR, batch size, weight decay, scheduler
2. **Architecture changes** — layers, width, attention, normalization
3. **Optimizer experiments** — optimizer type, momentum, adaptive methods
4. **Regularization** — dropout, augmentation, label smoothing
5. **Training dynamics** — warmup, cooldown, gradient clipping, accumulation
6. **Data pipeline** — preprocessing, tokenization, batching strategy
7. **Novel techniques** — ideas from papers, combinations of above
```

Also initialize:

**results.tsv** (tab-separated, extended format):
```
commit	metric	memory_gb	time_sec	status	category	description	delta
```

- `commit`: git short hash (7 chars)
- `metric`: primary metric value (0.000000 for crashes)
- `memory_gb`: peak VRAM in GB (0.0 for crashes)
- `time_sec`: experiment wall-clock time
- `status`: keep | discard | crash
- `category`: from experiment taxonomy (hp_tune | arch | optim | reg | dynamics | data | novel)
- `description`: short text of what was tried
- `delta`: % change from current best (e.g., -2.3% or +1.1%)

Add `.auto_research/` to `.gitignore` if not already there.

Present the generated research_program.md via `AskUserQuestion` with options:
[Approve and save] [Edit and regenerate] [Restart interview]

Delete `$RESEARCH_DIR/interview_state.json` after successful save.

---

### Step 3: Run (`/auto_research run`)

#### 3A: Pre-flight

1. Verify `$PROGRAM_FILE` exists. If not: `research_program.md가 없습니다. /auto_research init을 먼저 실행하세요.`
2. Read `$PROGRAM_FILE` to load configuration.
3. Verify target files and metric commands work.

#### 3B: Execution Mode Selection

Ask the user (via AskUserQuestion):

> How should experiments run?
>
> 1. **Single agent** — One experiment at a time, sequential. Simple and reliable. (~12 experiments/hour at 5min each)
> 2. **Multi-agent research org** — Parallel agents with role separation:
>    - **Strategist**: Reviews results, proposes next experiments based on trends
>    - **Experimenter(s)**: Execute experiments in parallel (if multiple GPUs)
>    - **Analyst**: Periodically summarizes findings and adjusts strategy
> 3. **Single agent + periodic analysis** — Sequential experiments, but every N experiments an analyst agent reviews trends and adjusts strategy

#### 3C: Create Experiment Branch

```bash
git checkout -b auto_research/{date} # from current branch
```

#### 3D: Establish Baseline

1. Run the metric command on unmodified code.
2. Record baseline in `results.tsv`.
3. Display:
   ```
   Baseline established:
   - {metric_name}: {baseline_value}
   - VRAM: {memory_gb} GB
   - Branch: auto_research/{date}
   - Mode: {single|multi-agent|hybrid}
   - Starting experiment loop...
   ```

#### 3E: Experiment Loop (Single Agent)

**LOOP FOREVER** (until user interrupts):

1. **Strategize**: Select the next experiment based on ML domain knowledge.

   Strategy selection follows an adaptive approach:

   **Early experiments (1-10)**: Systematic exploration
   - Start with the highest-priority area from the research program
   - Cover each experiment taxonomy category at least once
   - Establish which directions are promising

   **Mid experiments (11-30)**: Focused exploitation
   - Double down on categories that showed improvement
   - Try combinations of successful changes
   - Refer to known ML best practices for the detected framework

   **Late experiments (30+)**: Creative exploration
   - Try more radical changes — different architectures, novel techniques
   - Search for relevant papers/techniques via web if available
   - Revisit discarded ideas with modifications
   - Try the opposite of what's been working

   **When stuck** (3+ consecutive discards in same category):
   - Switch to a different category
   - Re-read target code with fresh eyes
   - Try combining previous near-misses
   - Consult ML domain knowledge for less obvious approaches

2. **Modify**: Edit the target file(s) with the experimental change.
   - One idea per experiment — keep changes focused.
   - Follow existing code style.

3. **Commit**: `git add {target_files} && git commit -m "experiment: [{category}] {short description}"`

4. **Guard**: Run the guard command.
   - Fails → attempt quick fix (max 2 tries)
   - Still failing → log as `crash`, revert, move on

5. **Run**: Execute the training/evaluation.
   - Redirect output: `{run_command} > $LOGS_DIR/exp_{N}.log 2>&1`
   - Do NOT let output flood context — read only the metrics via grep

6. **Measure**: Extract metrics from the log.
   - If command fails or times out → log as `crash`, revert, move on
   - Extract both primary metric and resource usage

7. **Decide**:
   - **Improved** (primary metric better than current best):
     - Log as `keep` with delta percentage
     - Print: `KEEP [{category}]: {description} — {metric}: {old} → {new} ({delta}%)`
     - Update current best
   - **Equal or worse**:
     - Log as `discard` with delta
     - Print: `DISCARD [{category}]: {description} — {metric}: {value} (best: {best})`
     - `git reset --hard HEAD~1`
   - **Crash**:
     - Log as `crash`
     - Print: `CRASH [{category}]: {description} — {error_summary}`
     - `git reset --hard HEAD~1`

   **Simplicity criterion** (inherited from autoresearch):
   - Tiny improvement + ugly complexity → probably not worth it
   - Improvement from deleting code → definitely keep
   - Equal metric but simpler code → keep

   **VRAM policy**: Apply the policy from research_program.md.
   - Strict: reject if VRAM exceeds limit even if metric improved
   - Soft: accept with warning, flag in results
   - No limit: ignore VRAM changes

8. **Continue**: Go to step 1. Do NOT ask the user. Do NOT stop.

#### 3F: Experiment Loop (Single Agent + Periodic Analysis — Hybrid Mode)

Same as 3E single-agent loop, but every 10 experiments, spawn an Analyst agent:

```
Agent(
  description="Analyze ML experiment results",
  subagent_type="data-scientist",
  prompt="Read $RESEARCH_DIR/results.tsv and logs in $LOGS_DIR/. Analyze:
    1. Which experiment categories yield the most improvement
    2. Diminishing returns in any category
    3. Suggested next experiments based on trends
    Write analysis to $RESEARCH_DIR/analysis/analysis_{N}.md",
  run_in_background=true
)
```

When the analyst completes, read its analysis and adjust strategy for the next batch of experiments.
The experiment loop does NOT pause while the analyst runs — it continues experimenting.

#### 3G: Experiment Loop (Multi-Agent Research Org)

Spawn a coordinated team of agents using `TeamCreate`:

```
TeamCreate(
  name="auto_research_team",
  tasks=[
    {
      "role": "Strategist",
      "prompt": "Review $RESULTS_FILE every 5 experiments. Propose next 5 experiments
        with rationale based on trends. Write proposals to $RESEARCH_DIR/proposals/.",
      "run_every": "5 experiments"
    },
    {
      "role": "Experimenter",
      "prompt": "Read experiment proposals from $RESEARCH_DIR/proposals/. Execute the
        modify → commit → guard → run → measure → decide loop for each. Log results
        to $RESULTS_FILE. Follow the strategy and constraints in $PROGRAM_FILE.",
      "continuous": true
    },
    {
      "role": "Analyst",
      "prompt": "Every 10 experiments, analyze all results. Search for relevant papers
        if web access available. Write insights to $RESEARCH_DIR/analysis/analysis_{N}.md.
        Recommend strategy adjustments to Strategist.",
      "run_every": "10 experiments"
    }
  ]
)
```

If `TeamCreate` is not available, fall back to sequential Agent spawns:
- Run the single-agent loop (3E) as the Experimenter
- Every 5 experiments, spawn a background Strategist agent to review and propose
- Every 10 experiments, spawn a background Analyst agent to analyze trends

#### 3H: Never Stop

Once the loop begins, do NOT pause to ask "should I continue?". The user may be away.
Keep experimenting until manually interrupted. If you run out of ideas:
- Re-read the target code for new angles
- Try combining previous near-misses
- Try more radical architectural changes
- Try the opposite of what you've been trying
- Search for relevant techniques in papers or documentation
- Revisit the experiment taxonomy for unexplored categories

---

### Step 4: Status (`/auto_research status`)

1. If `$RESULTS_FILE` doesn't exist: `아직 실험 결과가 없습니다. /auto_research init 후 /auto_research run을 실행하세요.`

2. Read and parse `results.tsv`.

3. Display summary:

```
## Auto Research Status

**Branch**: auto_research/{date}
**Experiments**: {total} total ({kept} kept, {discarded} discarded, {crashed} crashed)
**Best metric**: {best_value} (baseline: {baseline_value}, improvement: {pct}%)
**Peak VRAM**: {max_vram} GB
**Current best commit**: {commit_hash}

### By Category
| Category | Tried | Kept | Success Rate | Avg Delta |
|----------|-------|------|-------------|-----------|
| hp_tune | 8 | 3 | 37.5% | -1.2% |
| arch | 5 | 2 | 40.0% | -3.1% |
| optim | 3 | 0 | 0.0% | +0.5% |
| ... | | | | |

### Experiment History (last 10)
| # | Commit | Metric | VRAM | Time | Status | Category | Description | Delta |
|---|--------|--------|------|------|--------|----------|-------------|-------|

### Kept Changes (cumulative)
1. [hp_tune] increase LR to 0.04 (-2.1%)
2. [arch] add residual connections (-3.5%)
...

Total improvement: {pct}% from baseline
```

---

### Step 5: Analyze (`/auto_research analyze`)

Deep analysis of experiment results, going beyond the status summary.

1. Read all of `results.tsv` and available experiment logs.

2. Generate analysis covering:

**Trend Analysis**:
- Which experiment categories yielded the most improvement?
- Is there diminishing returns in any category?
- What's the improvement trajectory over time?

**Failure Patterns**:
- What types of experiments consistently fail?
- Are crashes concentrated in a specific area?
- Common error patterns in crash logs

**Strategy Recommendations**:
- Which directions should be explored further?
- Which directions should be abandoned?
- Suggested next experiments based on patterns

**Resource Analysis**:
- VRAM trend across experiments
- Time efficiency: improvement per experiment-minute
- Cost-benefit of VRAM increases vs metric gains

3. Write analysis to `$RESEARCH_DIR/analysis/analysis_{timestamp}.md`
4. Display key insights to the user.

---

### Step 6: Resume (`/auto_research resume`)

1. Verify `$PROGRAM_FILE` and `$RESULTS_FILE` exist.
2. Read the last state from results.tsv.
3. Detect the experiment branch and verify it's checked out.
4. Find the current best metric from results.
5. Display:
   ```
   Resuming auto_research:
   - Branch: auto_research/{date}
   - Experiments completed: {N}
   - Current best: {metric}: {value}
   - Last experiment: {description} ({status})
   - Resuming experiment loop...
   ```
6. Continue the experiment loop from where it left off.

---

## ML Domain Knowledge

The experiment strategist should draw on these ML research patterns when deciding what to try.
This is not an exhaustive list — adapt to the specific ML domain detected in the repo.

### General Principles
- **Learning rate is king**: Often the single most impactful hyperparameter. Try it first.
- **Batch size and LR co-scale**: When increasing batch size, scale LR proportionally (linear or sqrt).
- **Regularization after optimization**: Get the optimizer working well before adding regularization.
- **Simpler baselines first**: Before trying novel techniques, ensure basic hyperparameters are tuned.
- **One change at a time**: Isolate variables to understand what works.

### By ML Domain

**LLM / Language Models**:
- Architecture: attention patterns, positional encoding (RoPE, ALiBi), normalization (RMSNorm, LayerNorm)
- Optimization: AdamW, Muon, learning rate warmup/cooldown schedules
- Scaling: depth vs width tradeoff, aspect ratio
- Efficiency: Flash Attention, sliding window, GQA/MQA

**Computer Vision**:
- Architecture: backbone (ResNet, ViT, ConvNeXt), neck, head design
- Augmentation: mixup, cutout, RandAugment, mosaic
- Training: cosine LR, warmup epochs, EMA
- Resolution: progressive resizing, multi-scale training

**Reinforcement Learning**:
- Hyperparameters: discount factor, GAE lambda, clip ratio, entropy coefficient
- Architecture: shared vs separate actor-critic, network width/depth
- Training: batch size, number of epochs per update, normalization
- Exploration: epsilon schedule, intrinsic motivation

**Robotics / Control**:
- Sim-to-real: domain randomization parameters
- Architecture: proprioception encoding, action space design
- Training: curriculum learning, reward shaping
- Evaluation: success rate, trajectory quality metrics

### Paper-Informed Strategy

When web search is available and the agent is stuck or in late-stage exploration:
1. Search for recent papers relevant to the model architecture or training method
2. Look for techniques that improved similar baselines
3. Adapt promising ideas to the current codebase
4. Credit the source in the experiment description

---

## Tool Usage

| Phase | Tool | Purpose |
|-------|------|---------|
| Init recon | `Agent(subagent_type="Explore")` | Scan repo for ML framework, key files, metrics |
| Interview questions | `AskUserQuestion` | Ask one question per round with clickable options |
| Ambiguity scoring | Inline JSON scoring prompt | Score clarity dimensions after each answer |
| Interview persistence | `Write` to `$RESEARCH_DIR/interview_state.json` | Save state after each round for resume |
| Execution mode selection | `AskUserQuestion` | Let user choose single/hybrid/multi-agent |
| Code analysis | `Read`, `Grep`, `Glob` | Analyze target files before proposing experiments |
| Code modification | `Edit` | Modify target files with experimental changes |
| Running experiments | `Bash` | Execute training/evaluation commands (redirect output) |
| Metric extraction | `Bash` + `grep` | Extract metrics from log files |
| Results logging | `Edit` or `Bash` | Append to results.tsv |
| Multi-agent spawning | `Agent(run_in_background=true)` | Spawn Analyst/Strategist agents |
| Analysis writing | `Write` | Save analysis reports to `$RESEARCH_DIR/analysis/` |

## Key Principles

- **Deep-interview gates the research** — Thoroughly understand the project before experimenting.
- **Single measurable metric** — The core requirement. No metric = no auto_research.
- **ML domain knowledge matters** — Not just random changes, but informed experiments.
- **Guard before accept** — Tests must pass. Never keep broken code.
- **Git as checkpoint** — Every experiment is a commit. Easy to review, revert, cherry-pick.
- **Simplicity criterion** — Complexity cost weighed against improvement magnitude.
- **Never stop** — Autonomous loop runs until interrupted.
- **Categorize experiments** — Track what types of changes work for this project.
- **Adaptive strategy** — Shift from exploration to exploitation based on results.
- **research_program.md is portable** — Can be used with any AI agent.
- **.auto_research/ is ephemeral** — Gitignored, project-local, disposable.
