# OMO Workflow Guide

This document describes the end-to-end workflow from the user's perspective.

## Quick start

OMO is activated automatically when you give the orchestrator a complex task.
Simple edits (1-2 files, well-known patterns) are handled directly without orchestration.

## Example session

### Scenario: "Add a TypeScript utility function that debounces API calls"

**Step 1** — User gives the request.

The orchestrator detects this is non-trivial (new utility, needs research on debounce patterns).

**Step 2** — Orchestrator loads `omo-orchestrate` skill and follows its pipeline:

```
┌─ Pipeline ─────────────────────────────────────────────┐
│                                                        │
│  [1] Local-scout                                       │
│      → reads src/utils/ to understand existing pattern │
│      → writes scout-20260624-01.md                     │
│                                                        │
│  [2] Memory-reader                                     │
│      → loads omo-memory skill                          │
│      → no prior context found                          │
│                                                        │
│  [3] Web-RAG (needed? Yes — debounce patterns vary)    │
│      → loads omo-web-rag skill                         │
│      → searches "typescript debounce"                  │
│      → writes research-debounce-20260624-01.md         │
│                                                        │
│  [4] Plan                                              │
│      → writes plan-20260624-01.md                      │
│      Goal: create useDebounce hook                      │
│      Files: src/hooks/useDebounce.ts, src/hooks/index.ts│
│                                                        │
│  [5] Handoff (3+ files → non-trivial)                  │
│      → writes handoff-20260624-01.md                   │
│                                                        │
│  [6] Implement                                         │
│      → creates useDebounce.ts                          │
│      → updates index.ts                                │
│                                                        │
│  [7] Checkpoint                                        │
│      → writes checkpoint-20260624-01.md                │
│      → verifies all files touched                       │
│                                                        │
│  [8] Test & Review                                     │
│      → runs npm run typecheck (pass)                   │
│      → delegates to omo-reviewer subagent              │
│      → reviewer suggests adding TTL option             │
│                                                        │
│  [9] Summary & Memory                                  │
│      → writes summary-20260624-01.md                   │
│      → saves to memory via omo-memory skill            │
│                                                        │
└────────────────────────────────────────────────────────┘
```

**Step 3** — Orchestrator presents the result to the user with:
- What was created/modified
- Review feedback and how it was addressed
- Memory file locations for traceability

## When orchestration is skipped

Orchestration is skipped for:
- Single-file edits (e.g., "fix typo in README")
- Simple refactors (e.g., "rename this function")
- Answering questions about the codebase
- Running commands (e.g., "npm install")

These are handled directly by the build agent per global rules.

## Traceability

Every file in `.opencode/memory/` can be inspected:

```
ls .opencode/memory/
cat .opencode/memory/plan-20260624-01.md
cat .opencode/memory/handoff-20260624-01.md
cat .opencode/memory/checkpoint-20260624-01.md
```

This gives you full visibility into what the orchestrator decided and why.

## Recovering from interruptions

If a session is interrupted (e.g., network issue, model timeout):

1. Restart the session.
2. Say "continue from last checkpoint" or describe what you were doing.
3. The orchestrator will load memory, find the latest checkpoint, and resume.

## Customizing the workflow

You can modify any SKILL.md to change the workflow for your project:
- Add/remove stages
- Change model assignments
- Adjust checkpoint frequency
- Add project-specific validation steps
