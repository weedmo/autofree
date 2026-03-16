---
name: paper-review
description: "Robotics paper analysis skill — reads a PDF, extracts structure, generates summary + multi-model critical review (GPT/Gemini discussion with rating), and writes the result to Notion RFM database. Use /paper-review when the user mentions analyzing a paper, reviewing a paper PDF, or wants to add a paper review to Notion."
---

# Paper Review — Robotics Paper Analysis & Notion Export

Reads a robotics paper PDF, performs structured analysis, runs multi-model critical review via Codex (GPT) and Gemini, synthesizes ratings, and writes the result to the Notion RFM database.

- **Input**: PDF file path (or URL — download first)
- **Output**: Notion page in RFM database with structured analysis + multi-model review + figures
- **Domain**: Robotics, AI, embodied intelligence
- **Dependencies**: `document-skills:pdf` skill for extraction, `pdfimages`/`pdftoppm` for figures

## Procedure

### Step 0: Download PDF (if URL)

If input is a URL, download to `~/paper_reviews/`:
```bash
mkdir -p ~/paper_reviews && curl -sL -o ~/paper_reviews/{filename}.pdf "{url}"
```

### Step 1: Extract PDF Content

Use the `document-skills:pdf` skill capabilities. Extract text with pdfplumber and figures with pdftoppm:

```python
import pdfplumber

with pdfplumber.open("paper.pdf") as pdf:
    full_text = ""
    for page in pdf.pages:
        full_text += page.extract_text() or ""
        full_text += "\n"
```

If pdfplumber fails or text is empty (scanned PDF), fall back to OCR:

```python
import pytesseract
from pdf2image import convert_from_path

images = convert_from_path("paper.pdf")
full_text = "\n".join(pytesseract.image_to_string(img) for img in images)
```

### Step 1.5: Extract Figures

Extract **individual figures** (not full pages) from the PDF. Figures always have captions like "Fig. 1:", "Fig. 2:" etc.

**Step 1**: Identify which images are on which pages:
```bash
pdfimages -list paper.pdf | grep -v smask
```

**Step 2**: Extract all embedded images as JPEG:
```bash
mkdir -p ~/paper_reviews/{paper_slug}_figs
pdfimages -j paper.pdf ~/paper_reviews/{paper_slug}_figs/fig
```

**Step 3**: Identify key figures by cross-referencing page numbers and image sizes:
- Large images (>2000px wide) on early pages → main composite figures (Fig 1, 2, 3)
- Medium images (~1000-2000px) → diagrams, setup photos
- Small images (<800px) on same page → sub-components of a composite figure (skip these individually)

**Selection criteria**:
- **Always include**: Fig 1 (main overview/pipeline diagram) — placed at top of Notion page
- **Include if relevant**: Architecture diagrams, task illustrations, robot setup, key result charts
- **Skip**: Individual sub-plot images, masks (smask), small decorative elements

**Step 4**: Rename with descriptive names and upload to GitHub:
```bash
cd /tmp/paper-assets && mkdir -p {paper_slug}
cp ~/paper_reviews/{paper_slug}_figs/fig-000.jpg {paper_slug}/fig1-overview.jpg
# ... rename each by matching page number to figure caption
git add -A && git commit -m "feat: add {paper_slug} figures" && git push
```

Image URL pattern: `https://raw.githubusercontent.com/weedmo/paper-assets/main/{paper_slug}/{fig_name}.jpg`

**Notion insertion**: Use `![Fig N: caption](URL)` in appropriate sections. Main figure goes right after the rating callout, others near their relevant analysis sections.

### Step 2: Parse Paper Structure

Extract these sections from the full text (use heading patterns, common section names):

| Section | Extraction Pattern |
|---------|-------------------|
| Title | First prominent line or `\title{}` |
| Authors | Lines after title, before abstract |
| Abstract | "Abstract" heading to next section |
| Introduction | "Introduction" or "1." section |
| Related Work | "Related Work" or "2." section |
| Methods | "Method(s/ology)" or "Approach" section |
| Experiments/Results | "Experiment(s)" or "Results" section |
| Discussion/Conclusion | "Discussion" or "Conclusion" section |
| References | "References" or "Bibliography" section |

Also extract:
- **Keywords** from abstract or keyword section
- **URLs/DOIs** via regex `10\.\d{4,}/\S+` or `https?://\S+`
- **Figures/Tables count** from captions like "Figure N" or "Table N"

### Step 3: Generate Analysis (Claude)

Claude performs a robotics-domain analysis covering:

**Summary (요약)**:
- One-paragraph core contribution
- Problem statement and motivation
- Proposed approach in 2-3 sentences
- Key results and metrics

**Methodology Analysis (방법론 분석)**:
- Architecture/system design overview
- Training pipeline or data collection method
- Key technical innovations
- Comparison with prior approaches

**Strengths (강점)**:
- Novel contributions to the robotics field
- Experimental rigor (real robot vs sim-only, number of trials, environments)
- Reproducibility (code/data availability)

**Limitations (한계점)**:
- Scalability concerns
- Sim-to-real gap if applicable
- Missing baselines or ablations
- Generalization across tasks/environments

**Practical Relevance (실무 적용성)**:
- Applicability to real-world robotics deployment
- Hardware requirements and constraints
- Integration complexity with existing systems

### Step 4: Multi-Model Critical Review

Run Codex and Gemini reviews **in parallel** using the `omc ask` command:

**Codex prompt** (technical rigor focus):
```
You are a robotics research reviewer. Analyze this paper critically:

Title: {title}
Abstract: {abstract}
Key Methods: {methods_summary}
Results: {results_summary}

Evaluate:
1. Technical soundness (methodology, math, experimental design)
2. Novelty compared to prior work (VLA, diffusion policy, etc.)
3. Reproducibility (code, data, hardware specs)
4. Statistical rigor (error bars, number of trials, ablations)
5. Rating: 1-10 with justification

Be specific. Cite exact claims from the paper.
```

**Gemini prompt** (impact & clarity focus):
```
You are a robotics research reviewer. Analyze this paper critically:

Title: {title}
Abstract: {abstract}
Key Methods: {methods_summary}
Results: {results_summary}

Evaluate:
1. Clarity of writing and presentation
2. Significance of contribution to the robotics community
3. Real-world applicability and deployment feasibility
4. Comparison completeness (missing baselines?)
5. Rating: 1-10 with justification

Be specific. Cite exact claims from the paper.
```

Execution:

```bash
omc ask codex "{codex_prompt}"
omc ask gemini "{gemini_prompt}"
```

Read the artifacts from `.omc/artifacts/ask/codex-*.md` and `.omc/artifacts/ask/gemini-*.md`.

### Step 5: Synthesize Ratings

Claude synthesizes the three reviews (Claude + Codex + Gemini):

1. **Individual Ratings Table**: Show each model's score (1-10) and key points
2. **Agreement Points**: Where all models agree
3. **Disagreements**: Where models diverge, with Claude's arbitration
4. **Final Rating**: Weighted average with Claude's judgment
   - Technical Soundness: /10
   - Novelty: /10
   - Practical Relevance: /10
   - Overall: /10

Rating scale:
- 9-10: Top-tier, must-read for the field
- 7-8: Strong contribution, worth implementing
- 5-6: Incremental, some useful ideas
- 3-4: Weak, significant issues
- 1-2: Fundamental flaws

### Step 5.5: Generate Key Concepts Explanation

Identify 4-6 technical concepts from the paper that may be unfamiliar or difficult to understand. For each concept, write a concise explanation with:

- **What it is**: One-sentence definition
- **Why it matters**: Role in this paper's approach
- **Intuitive analogy or comparison**: Connect to familiar concepts
- **Key formula or diagram** (if applicable): Simplified representation
- **Highlight important caveats**: Use `<span color="yellow_bg">text</span>` for critical points

Common robotics/ML concepts to explain when present:
- RL fundamentals: advantage, value function, policy, reward shaping
- Generative models: flow matching, diffusion, classifier-free guidance (CFG)
- Imitation learning: DAgger, behavior cloning, dataset aggregation
- VLA-specific: action chunking, multi-modal conditioning, sub-task prediction
- Training paradigms: offline RL vs online RL, pre-training vs fine-tuning

This section goes into a toggle heading `## 핵심 개념 설명 {toggle="true" color="blue"}` in the Notion page, placed between "Practical Relevance" and the divider before "Multi-Model Critical Review". Each concept gets an `### {Concept Name}` subheading inside the toggle.

### Step 6: Determine Tags

Auto-assign tags from the RFM database options based on paper content:

| Tag | Trigger Keywords |
|-----|-----------------|
| `VLA` | vision-language-action, VLA, multimodal policy, language-conditioned |
| `data collection` | dataset, data collection, teleoperation, demonstration |
| `retrieval` | retrieval, RAG, nearest-neighbor, memory-augmented |

Multiple tags can apply. If no tag matches, leave empty.

### Step 7: Show Draft & Confirm

Present the complete analysis to the user before writing to Notion:

```
## Paper Review Draft

**Title**: {title}
**Authors**: {authors}
**Tags**: {tags}
**URL/DOI**: {url}

### Summary
...

### Multi-Model Review
| Model | Rating | Key Point |
|-------|--------|-----------|
| Claude | 7/10 | ... |
| Codex (GPT) | 8/10 | ... |
| Gemini | 7/10 | ... |
| **Overall** | **7.3/10** | ... |

---

이 내용으로 RFM 데이터베이스에 추가할까요?
(수정할 부분이 있으면 말씀해주세요)
```

Wait for user confirmation via AskUserQuestion.

### Step 8: Create Notion Page

**Target database**: RFM database in Paper page
- Database URL: `https://www.notion.so/2b539aa2512b8047ba06d7c144db2422`
- Data source: `collection://2b539aa2-512b-80a8-96e0-000bbd97d9d4`

**Page properties**:
```json
{
  "이름": "{paper_title}",
  "태그": ["{matched_tags}"],
  "userDefined:url": "{doi_or_url}",
  "상태": "완료"
}
```

**Page content** — Use Notion-flavored Markdown with rich formatting:

```markdown
<callout color="blue_bg">
**Overall Rating: {overall}/10** | Technical: {tech}/10 | Novelty: {novel}/10 | Practical: {practical}/10
</callout>

<columns>
<column>
**Authors**: {authors}
**Published**: {year}
**URL**: [{url_short}]({url})
</column>
<column>
**Figures**: {fig_count} | **Tables**: {table_count}
**Pages**: {page_count}
**Keywords**: {keywords}
</column>
</columns>

---

## Summary

{one_paragraph_summary}

## Methodology

{methodology_analysis}

## Strengths

{strengths_as_bullet_list}

## Limitations

{limitations_as_bullet_list}

## Practical Relevance

{practical_relevance}

---

## 핵심 개념 설명 {toggle="true" color="blue"}

### {Concept 1 Name}

{explanation with intuitive analogy, formula if applicable, yellow highlights for caveats}

### {Concept 2 Name}

{explanation}

(4-6 concepts total, selected based on paper content)

---

## Multi-Model Critical Review {toggle="true" color="gray"}

### Claude Analysis

{claude_review}

### Codex (GPT) Analysis

{codex_review}

### Gemini Analysis

{gemini_review}

## Rating Discussion {toggle="true" color="gray"}

<table header-row="true" fit-page-width="true">
<colgroup>
<col color="gray">
<col>
<col>
<col>
<col>
</colgroup>
<tr>
<td>Model</td>
<td>Technical</td>
<td>Novelty</td>
<td>Practical</td>
<td>Overall</td>
</tr>
<tr>
<td>Claude</td>
<td>{c_tech}/10</td>
<td>{c_novel}/10</td>
<td>{c_practical}/10</td>
<td>{c_overall}/10</td>
</tr>
<tr>
<td>Codex (GPT)</td>
<td>{g_tech}/10</td>
<td>{g_novel}/10</td>
<td>{g_practical}/10</td>
<td>{g_overall}/10</td>
</tr>
<tr>
<td>Gemini</td>
<td>{gem_tech}/10</td>
<td>{gem_novel}/10</td>
<td>{gem_practical}/10</td>
<td>{gem_overall}/10</td>
</tr>
<tr color="blue_bg">
<td>**Final**</td>
<td>**{f_tech}/10**</td>
<td>**{f_novel}/10**</td>
<td>**{f_practical}/10**</td>
<td>**{f_overall}/10**</td>
</tr>
</table>

### Agreement

{agreement_points}

### Disagreements

{disagreement_points_with_arbitration}
```

Use `mcp__notion__notion-create-pages` to create the page in the RFM database.
Display the created page URL to the user.

## Formatting Rules

- No emoji icons anywhere
- Korean section headers (요약, 방법론, 강점, 한계점, 실무 적용성)
- But keep "Summary", "Methodology" etc. in Notion headings for international readability
- Rating callout at top with `blue_bg`
- Multi-model reviews in toggle headings (collapsed by default)
- Code blocks with language tags
- Tables with `header-row="true"` and column colors
- Yellow highlight for critical findings: `<span color="yellow_bg">text</span>`
- Dividers between main analysis and detailed reviews

## Error Handling

- **pdfplumber fails**: Try pypdf, then OCR fallback
- **Codex CLI unavailable**: Continue with Gemini + Claude only, note limitation
- **Gemini CLI unavailable**: Continue with Codex + Claude only, note limitation
- **Both CLIs unavailable**: Claude-only review, clearly state single-model limitation
- **Notion API fails**: Save as markdown to `~/paper_reviews/PAPER-YYYY-NNN-{slug}.md`
