# OMO Architecture

OMO (Oh-My-Orchestrator) is a **skill-centered multi-agent orchestration layer** for OpenCode.
It transforms the default single-agent OpenCode session into a guided, traceable pipeline.

## Design principles

| Principle | Meaning |
|-----------|---------|
| Skill-first | Complex workflows start by loading a skill, not by hardcoding agent calls. |
| Traceability | Every stage writes an artifact to `.opencode/memory/`. No silent decisions. |
| Minimal subagents | Subagents exist but are used sparingly — only when specialized models/tools are needed. |
| Hybrid autonomy | The orchestrator drives the workflow but pauses at checkpoints for user review. |
| Free-model friendly | All agents use free/cheap models by default. Model assignments in `opencode.jsonc` are examples — override per environment. |

## Component overview

```
User
  │
  ▼
┌─────────────────────────────────────────────────────┐
│  build agent (Orchestrator)                         │
│  ● follows AGENTS.md rules                          │
│  ● loads omo-orchestrate skill for complex tasks    │
│  ● uses task() subagents only when skill says to    │
│  ● writes checkpoint files after each stage         │
└──────┬──────────────────────────────────────────────┘
       │ loads
       ▼
┌─────────────────────────────────────────────────────┐
│  omo-orchestrate (SKILL.md)                         │
│  ● Stage 1: Local-scout                             │
│  ● Stage 2: Memory-reader (→ omo-memory skill)      │
│  ● Stage 3: Web-RAG (→ omo-web-rag skill | subagent)│
│  ● Stage 4: Plan                                    │
│  ● Stage 5: Handoff                                 │
│  ● Stage 6: Implement                               │
│  ● Stage 7: Checkpoint                              │
│  ● Stage 8: Test & Review (→ omo-reviewer subagent) │
│  ● Stage 9: Summary & Memory (→ omo-memory skill)   │
└─────────────────────────────────────────────────────┘
```

## File layout

```
omo/
├── AGENTS.md                 # Orchestrator rules (project-level)
├── opencode.jsonc            # Agent registration + permissions
│
├── .opencode/
│   ├── agents/
│   │   ├── omo-researcher.md   # Web RAG subagent (deep research)
│   │   └── omo-reviewer.md     # Code review subagent
│   │
│   ├── skills/
│   │   ├── omo-orchestrate/    # ★ Entry point
│   │   ├── omo-memory/         # Memory CRUD
│   │   └── omo-web-rag/        # Lightweight RAG workflow
│   │
│   └── memory/                 # Persistent flat-file memory
│
└── docs/
    ├── ARCHITECTURE.md         # This file
    └── WORKFLOW.md             # User-facing workflow guide
```

## Agent roles

| Agent | Model (example) | Tools | When used |
|-------|------------------|-------|-----------|
| `build` (orchestrator) | coding model | All | Always — the default agent |
| `omo-researcher` | cheap model | websearch, webfetch, memory write | Heavy web RAG (optional) |
| `omo-reviewer` | large-context model | git diff, memory write | Final review stage |

## Skill loading hierarchy

```
┌─ orchestrator loads ──────────────────────┐
│                                            │
│  omo-orchestrate (master)                  │
│    ├── internally loads omo-memory skill   │
│    ├── internally loads omo-web-rag skill  │
│    └── conditionally delegates to:         │
│         ├── omo-researcher subagent        │
│         └── omo-reviewer subagent          │
└────────────────────────────────────────────┘
```

## Memory file life cycle

```
scout-*.md  ← Stage 1
plan-*.md   ← Stage 4
handoff-*.md ← Stage 5 (non-trivial only)
checkpoint-*.md ← Stage 7
review-*.md ← Stage 8 (written by reviewer subagent)
summary-*.md ← Stage 9
research-*.md ← Stage 3 (written by web-rag)
```

All files live in `.opencode/memory/` and use YAML frontmatter for metadata.
