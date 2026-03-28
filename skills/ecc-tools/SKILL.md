---
name: ecc-tools
description: "ECC (Everything Claude Code) skill combination advisor. Given a task specification, recommends the optimal combination of document-skills plugin skills to use together. Trigger this skill when the user describes a complex task that could benefit from multiple ECC skills working together, asks 'which skills should I use for this?', mentions combining skills, or wants guidance on skill workflow for documents, presentations, web artifacts, APIs, or design tasks. Also trigger when user says 'ecc', 'ecc-tools', or asks about available document-skills."
---

# ECC Tools — Skill Combination Advisor

When the user describes a task, analyze it and recommend which ECC (Everything Claude Code / document-skills) skills to combine, in what order, and why. The goal is to help users get the most out of the skill ecosystem by showing how skills compose together.

## ECC Skill Catalog

| Skill | What It Does |
|-------|-------------|
| `pdf` | Read, create, merge, split, watermark, OCR, encrypt PDF files |
| `xlsx` | Read, create, edit spreadsheets (.xlsx, .csv, .tsv) — formulas, charts, formatting |
| `docx` | Create, read, edit Word documents — TOC, headers, page numbers, images |
| `pptx` | Create, read, edit PowerPoint presentations — slides, layouts, speaker notes |
| `frontend-design` | Production-grade web UI — websites, landing pages, dashboards, React components |
| `web-artifacts-builder` | Complex multi-component HTML artifacts with React, Tailwind, shadcn/ui |
| `canvas-design` | Static visual art — posters, designs as .png/.pdf |
| `algorithmic-art` | Generative art with p5.js — flow fields, particle systems, seeded randomness |
| `theme-factory` | Apply or generate visual themes (colors/fonts) for any artifact |
| `brand-guidelines` | Apply Anthropic brand colors and typography |
| `doc-coauthoring` | Structured co-authoring workflow for docs, proposals, specs |
| `internal-comms` | Company internal communications — status reports, updates, newsletters |
| `claude-api` | Build apps with Claude API / Anthropic SDK / Agent SDK |
| `mcp-builder` | Create MCP servers for LLM-service integration (Python FastMCP / Node SDK) |
| `webapp-testing` | Test local web apps with Playwright — screenshots, logs, UI verification |
| `slack-gif-creator` | Animated GIFs optimized for Slack |
| `skill-creator` | Create, improve, and benchmark skills |

## Procedure

### Step 1: Parse the Specification

Read the user's task description and extract:
- **Deliverables**: what files or artifacts need to be produced
- **Data flow**: what goes in, what processing happens, what comes out
- **Quality needs**: branding, theming, testing, iteration requirements

### Step 2: Map to Skills

For each deliverable or processing step, identify the matching ECC skill. Look for combinations where one skill's output feeds into another.

Common combination patterns:

| Task Pattern | Skill Pipeline |
|-------------|---------------|
| Branded report from data | `xlsx` (analyze) → `docx` (write) → `brand-guidelines` (style) |
| Company presentation | `doc-coauthoring` (draft) → `pptx` (create) → `theme-factory` (style) |
| Dashboard from spreadsheet | `xlsx` (read data) → `frontend-design` (build UI) → `webapp-testing` (verify) |
| Styled landing page | `frontend-design` (build) → `theme-factory` (theme) → `webapp-testing` (test) |
| PDF report with charts | `xlsx` (charts) → `docx` (compose) → `pdf` (export) |
| Interactive web artifact | `web-artifacts-builder` (build) → `theme-factory` (style) |
| API integration tool | `claude-api` or `mcp-builder` (build) → `webapp-testing` (test) |
| Internal status update | `internal-comms` (draft) → `pptx` (slides) or `docx` (doc) |
| Generative art poster | `algorithmic-art` (generate) → `canvas-design` (compose) |
| Research doc workflow | `doc-coauthoring` (interview+draft) → `docx` (format) → `pdf` (publish) |

### Step 3: Present the Recommendation

Use this format:

```
[Task Summary]

Recommended skill pipeline:

1. /document-skills:skill-name — purpose in this pipeline
2. /document-skills:skill-name — purpose in this pipeline
3. /document-skills:skill-name — purpose in this pipeline

Execution order: 1 → 2 → 3 (or 1,2 parallel → 3)

Notes:
- any relevant tips about how the skills interact
- alternative approaches if applicable
```

Guidelines:
- Order skills by execution sequence (data flows from earlier to later)
- Mark parallel-safe steps (skills that can run independently)
- Keep it concise — only recommend skills that genuinely add value
- If only 1 skill is needed, say so — don't pad the recommendation
- If no ECC skill fits, say so clearly

### Step 4: Execute on Confirmation

When the user confirms the pipeline:
- Invoke skills in the recommended order using the Skill tool
- Pass relevant context and outputs between steps
- If a step fails, suggest an alternative skill or approach

## When NOT to Trigger

- User already invoked a specific skill with `/document-skills:xxx`
- Task has nothing to do with documents, design, web artifacts, or APIs
- Simple single-skill tasks where the skill will auto-trigger on its own
