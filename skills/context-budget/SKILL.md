---
name: context-budget
description: Audits Claude Code context window consumption across agents, skills, MCP servers, and rules. Distinguishes always-loaded vs on-demand overhead for accurate token budgeting.
origin: ECC (modified)
---

# Context Budget

Analyze token overhead across every loaded component in a Claude Code session and surface actionable optimizations to reclaim context space.

## Key Concept: Always-Loaded vs On-Demand

Not all components consume tokens equally. Distinguish:

| Load type | When consumed | Examples |
|-----------|--------------|----------|
| **Always-loaded** | Every turn, injected into system prompt | CLAUDE.md, agent descriptions (frontmatter), skill list descriptions, MCP tool schemas, rules, deferred tool names, hooks, memory index |
| **On-demand** | Only when explicitly invoked | SKILL.md full content (loaded on `/skill`), agent body (loaded on spawn), MCP tool full schema (loaded on `ToolSearch`) |

**Critical**: only report always-loaded tokens as "overhead". On-demand content is pay-per-use and should be reported separately as "invocation cost".

## When to Use

- Session performance feels sluggish or output quality is degrading
- You've recently added many skills, agents, or MCP servers
- You want to know how much context headroom you actually have
- Planning to add more components and need to know if there's room

## How It Works

### Phase 1: Inventory (Always-Loaded)

Scan and estimate **per-turn** token consumption:

**CLAUDE.md chain** (project + user-level)
- Count tokens per file in the CLAUDE.md chain
- Flag: combined total >300 lines

**Agent descriptions** (`agents/*.md` frontmatter only)
- Extract `description` field from frontmatter (this is injected into Task tool definition)
- Estimate: description word count × 1.3
- Flag: description >30 words (bloated)
- Note: agent body is NOT always-loaded, only loaded on spawn

**Skill list descriptions** (system-reminder skill listing)
- Each installed skill adds ~30-50 words to the system-reminder listing
- Estimate: skill count × 40 words × 1.3
- Flag: >30 skills listed (noise increases mismatching risk)

**MCP tool names** (deferred tool list in system-reminder)
- Each registered MCP tool name appears in the deferred tool list
- Estimate: ~10 tokens per tool name entry
- Full schemas (~500 tok/tool) are loaded only on `ToolSearch` invocation
- Flag: >100 deferred tool names, servers with >20 tools

**Rules** (`rules/**/*.md`)
- Count tokens per file (always injected)
- Flag: files >100 lines

**Hooks output** (system-reminder injections)
- Estimate overhead from hook messages that inject into every turn
- Flag: verbose hook outputs that add >200 words per turn

**Memory index** (MEMORY.md)
- Count tokens in MEMORY.md (always loaded, truncated at 200 lines)

### Phase 2: Inventory (On-Demand)

Report separately — these are NOT per-turn overhead but invocation costs:

**Skill full content** (`skills/*/SKILL.md`)
- Count tokens per SKILL.md file
- Flag: files >400 lines (heavy when invoked)
- This is loaded ONLY when `/skill-name` is invoked

**Agent full body** (`agents/*.md` body after frontmatter)
- Count tokens per agent body
- Flag: files >200 lines
- This is loaded ONLY when agent is spawned via Task tool

**MCP tool full schemas**
- ~500 tokens per tool when fetched via ToolSearch
- Loaded ONLY when tools are actually fetched for use

### Phase 3: Classify

Sort always-loaded components into buckets:

| Bucket | Criteria | Action |
|--------|----------|--------|
| **Essential** | Referenced in CLAUDE.md, core workflow, or matches current project | Keep |
| **Low-value** | No project match, rarely used, or adds noise | Consider removing |
| **Redundant** | Overlapping functionality, duplicate content | Consolidate or remove |

### Phase 4: Detect Issues

Identify problem patterns:

- **Bloated agent descriptions** — description >30 words in frontmatter
- **Skill list noise** — >30 skills listed, increasing mismatch risk
- **MCP over-subscription** — >100 deferred tool names, or redundant servers (e.g. chrome-devtools + playwright)
- **CLAUDE.md bloat** — verbose explanations, outdated sections
- **Hook verbosity** — hooks injecting large text blocks every turn
- **Redundant components** — skills that overlap, servers that duplicate CLI tools

### Phase 5: Report

```
Context Budget Report
═══════════════════════════════════════

Context model: [model name] ([window size])

Always-Loaded (per-turn overhead):
┌─────────────────────┬────────┬───────────┐
│ Component           │ Count  │ Tokens    │
├─────────────────────┼────────┼───────────┤
│ CLAUDE.md           │ N      │ ~X,XXX    │
│ Agent descriptions  │ N      │ ~XXX      │
│ Skill list          │ N      │ ~X,XXX    │
│ MCP tool names      │ N      │ ~X,XXX    │
│ Rules               │ N      │ ~XXX      │
│ Hooks overhead      │ N      │ ~XXX      │
│ Memory index        │ 1      │ ~XXX      │
├─────────────────────┼────────┼───────────┤
│ TOTAL per-turn      │        │ ~XX,XXX   │
└─────────────────────┴────────┴───────────┘

Effective available context: ~XXX,XXX tokens (XX%)

On-Demand (pay-per-use):
┌─────────────────────┬────────┬───────────┐
│ Component           │ Count  │ Tokens    │
├─────────────────────┼────────┼───────────┤
│ Skill full content  │ N      │ ~XXX,XXX  │
│ Agent bodies        │ N      │ ~X,XXX    │
│ MCP full schemas    │ N      │ ~XX,XXX   │
└─────────────────────┴────────┴───────────┘
(loaded only when invoked — not counted as overhead)

⚠ Issues Found (N):
[ranked by per-turn token savings]

Top 3 Optimizations:
1. [action] → save ~X,XXX tokens/turn
2. [action] → save ~X,XXX tokens/turn
3. [action] → save ~X,XXX tokens/turn
```

## Token Estimation Rules

| Content type | Formula |
|-------------|---------|
| Prose (CLAUDE.md, rules, descriptions) | words × 1.3 |
| Code-heavy files | chars / 4 |
| Skill list entries | count × 52 (avg 40 words × 1.3) |
| MCP deferred tool names | count × 10 |
| MCP full tool schemas | count × 500 (on-demand only) |

## Best Practices

- **MCP tool names are the biggest always-loaded lever** — each tool adds ~10 tokens to the deferred list, and 100+ tools means 1000+ tokens just for names
- **Skill list noise matters more than skill size** — a 2000-line skill costs 0 tokens until invoked, but its 40-word listing is always present
- **Agent descriptions load always** — keep them under 30 words
- **Audit after changes** — run after adding any component to catch creep
- **Focus optimizations on always-loaded** — removing an on-demand component saves nothing until it's invoked
