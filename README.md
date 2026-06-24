# OMO (Oh-My-Orchestrator)

Skill-centered multi-agent orchestration layer for OpenCode.

## Quick start

1. Clone this repo (or copy its contents into any OpenCode project).
2. OpenCode automatically reads `AGENTS.md`, `opencode.jsonc`, `.opencode/agents/`, and `.opencode/skills/`.
3. Give a complex task to the build agent — it will load the `omo-orchestrate` skill and follow the 9-stage pipeline.

## Prerequisites

- [OpenCode](https://opencode.ai) CLI
- One or more LLM providers configured in `~/.config/opencode/opencode.json`

## Structure

```
AGENTS.md              Orchestrator rules
opencode.jsonc         Agent registration & permissions
.opencode/agents/      Subagent definitions (researcher, reviewer)
.opencode/skills/      Skill packs (orchestrate, memory, web-rag)
.opencode/memory/      Persistent flat-file memory (auto-generated)
docs/                  Architecture & workflow documentation
```

## How it works

| Component | Role |
|-----------|------|
| `omo-orchestrate` skill | Entry point — routes complex tasks through a 9-stage pipeline |
| `omo-memory` skill | Read/write/search persistent context |
| `omo-web-rag` skill | Lightweight internet research workflow |
| `omo-researcher` agent | Deep web RAG (used when web-rag skill is insufficient) |
| `omo-reviewer` agent | Code review via git diff |

## Customization

- Edit `.opencode/skills/omo-orchestrate/SKILL.md` to modify the pipeline.
- Override model assignments in `opencode.jsonc` → `agent.<name>.model`.
- See `docs/WORKFLOW.md` for a walkthrough.

## License

MIT
