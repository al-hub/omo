---
name: omo-web-rag
description: Lightweight internet RAG workflow. Search web, fetch sources, and synthesize into memory.
compatibility: opencode
metadata:
  stage: research
  workflow: rag
---

# OMO Web RAG — Internet Research Workflow

Use this skill when the current task requires external information not available in the local codebase or memory.

## When to use
- Learning a new library or framework
- Checking latest API documentation
- Researching best practices for a specific problem
- Finding alternatives or comparisons

## When NOT to use
- The answer is clearly in the local codebase
- The task uses well-known, stable patterns you already know
- The user explicitly says "no need to search"

## Workflow

### Step 1: Formulate search queries

Identify 1-3 specific search queries. Each query should be:
- Focused on one aspect of the research need
- Using keywords likely to appear in docs, tutorials, or reference pages

### Step 2: Search

Use `websearch` with each query. Configure:
- `numResults`: 5 (enough for breadth without noise)
- `type`: "auto" (balanced quality/speed)

### Step 3: Fetch & filter

For each promising search result:
1. Use `webfetch` to retrieve the page.
2. Check: is this authoritative (official docs, well-known source)?
3. If yes, extract key information. If no, skip.

Limit to 3-5 total fetches to stay within token budget.

### Step 4: Synthesize

Create a research summary:

```
Artifact: .opencode/memory/research-{topic}-{YYYYMMDD}-{seq}.md
```

Format:
```yaml
---
stage: research
topic: <topic>
timestamp: <ISO8601>
sources:
  - <url>
  - <url>
---
## Summary
<2-3 paragraph synthesis>

## Key findings
- <finding 1>
- <finding 2>

## Source notes
- <url>: <what this source contributed>
```

### Step 5: Return

Tell the orchestrator:
- The research file path
- One-paragraph summary of findings
- Whether you recommend any specific approach

## Deep research (subagent delegation)

If the topic is very broad or requires deep investigation:
1. Note "recommending subagent delegation due to scope".
2. The orchestrator will decide whether to call `omo-researcher`.
3. If delegated, `omo-researcher` will use the same general pattern but with more thoroughness.
