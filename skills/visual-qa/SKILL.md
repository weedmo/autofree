---
name: visual-qa
description: "Visual/design QA pipeline: design-consultation → design-review → design-html. Chains design skills for visual consistency checks, AI slop detection, and design polish. Use /visual-qa for design audit with fixes, /visual-qa audit for report-only."
---

# Visual QA — Design Review Pipeline

Orchestrates visual quality checks by chaining design-related skills.
Finds spacing issues, hierarchy problems, AI slop patterns, and visual inconsistencies.

## When to Use

- Visual polish before release
- Design system compliance check
- AI slop cleanup (generic gradients, placeholder text, inconsistent spacing)
- After implementing new UI components

## Modes

| Command | Mode | Skills Chain |
|---------|------|-------------|
| `/visual-qa <url>` | Full | design-review → design-html (fix) |
| `/visual-qa audit <url>` | Audit-only | plan-design-review (report) |
| `/visual-qa system` | Design system | design-consultation → DESIGN.md |
| `/visual-qa explore <url>` | Variants | design-shotgun → comparison |

## Procedure

### Phase 1: Design System Check

Check if `DESIGN.md` exists in the project root:
- **Exists** → Read it, use as the design reference
- **Missing** → Ask user:
  - "Want me to establish a design system first?" → Invoke `/design-consultation`
  - "Skip, just review" → Use sensible defaults

### Phase 2: Pre-capture

Invoke `/browse` to capture current state:
```
browse <url> --snapshot
```
- Full page screenshot (desktop)
- Responsive screenshots if relevant (mobile, tablet)
- Note current font stack, color usage, spacing patterns

### Phase 3: Visual Audit

**Full mode** → Invoke `/design-review`:
- Spacing inconsistencies
- Typography hierarchy issues
- Color contrast violations
- AI slop patterns (generic gradients, stock imagery, placeholder text)
- Slow interactions / animation jank
- Fixes each issue atomically with before/after screenshots

**Audit-only mode** → Invoke `/plan-design-review`:
- Rates each design dimension 0-10
- Explains what would make each a 10
- No code changes

### Phase 4: Implementation (Full mode only)

If design-review identified structural changes needed:
1. Invoke `/design-html` to generate production-quality HTML/CSS
2. Compare with existing implementation
3. Apply changes atomically

### Phase 5: Verification

After all fixes:
1. Re-capture screenshots with `/browse`
2. Side-by-side comparison: before vs after
3. Verify no visual regressions introduced

### Phase 6: Cross-check with Functional QA

If visual changes touched interactive elements:
- Invoke `/qa-flow verify <url>` to ensure functionality intact
- Or run a quick `/browse` interaction test on affected flows

### Phase 7: Connect to Real Browser (optional)

If user wants hands-on verification:
```
Invoke /connect-chrome
```
- User can see changes in real Chrome
- Side Panel shows live activity feed

## AI Slop Detection Checklist

The design-review phase specifically checks for:
- [ ] Generic hero gradients (purple-to-blue syndrome)
- [ ] Placeholder/lorem ipsum text left in
- [ ] Inconsistent border-radius across components
- [ ] Shadow depth inconsistency
- [ ] Button style proliferation (>3 distinct button styles)
- [ ] Spacing that doesn't follow a consistent scale
- [ ] Font weight soup (too many weights without hierarchy)
- [ ] Color values that don't match the design system

## Output

At completion, report:
1. Issues found / fixed / remaining
2. Design dimension scores (if audit mode)
3. Before/after screenshot comparison
4. DESIGN.md created or updated (if applicable)
