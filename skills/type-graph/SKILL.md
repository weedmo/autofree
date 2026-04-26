<!-- ~/.claude/skills/type-graph/SKILL.md -->
---
name: type-graph
description: Function-level type and call graph for Python codebases (ROS rqt_graph-style). Trigger /type-graph
trigger: /type-graph
---

# /type-graph

Build a navigable, ROS-`rqt_graph`-style visualization of a Python codebase: functions are nodes (with input/output type signatures + a one-line role), calls are directed edges, module/package prefixes form clusters, and v0 keeps `passed_types` empty for later type-flow work.

## Usage

```
/type-graph                          # analyze cwd
/type-graph <path>                   # analyze a specific path
/type-graph <path> --infer           # run Pyright diagnostics and record counts
/type-graph <path> --no-llm          # skip LLM-written role / cluster summaries
/type-graph <path> --update          # incremental: only changed files
/type-graph <path> --open            # open graph.html after rendering

/type-graph explain <fn_id>          # signature + role + callers/callees
/type-graph path <fn_a> <fn_b>       # shortest call path
/type-graph query "<question>"       # natural-language Q over the graph
```

## What you must do when invoked

1. **Verify the package is installed.**
   - Run `python -c "import type_graph"`. If it fails, suggest:
     `python -m pip install -e /home/weed/type-graph` (development install) or
     `pip install type-graph` (once published).
2. **Resolve the target path.** Default to current working directory.
3. **Invoke the CLI.** Forward all flags. Capture exit code.
4. **Report.** Print the headline statistics from `<out>/REPORT.md` (function count, edge count, unresolved-call ratio, role_source distribution) and the absolute path to `graph.html`. Suggest `--open` if not already used.
5. **Subcommands.** For `explain` / `path` / `query`, ensure a prior `graph.json` exists in the resolved out directory; if not, run analyze first.

## Honesty rules

- Never paraphrase role text. The skill should display roles verbatim from REPORT, with the `role_source` badge.
- If `--infer` was requested but Pyright is not installed, surface the CLI's exit code 3 and its stderr verbatim. Do not attempt fallback.

## Output location

Default `<cwd>/type-graph-out/`. Override with `--out <dir>`.
