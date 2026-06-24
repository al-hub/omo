# OMO (Oh-My-Orchestrator)

Skill-centered multi-agent orchestration layer for OpenCode.

## Quick start

1. Clone this repo (or copy its contents into any OpenCode project).
2. OpenCode automatically reads `AGENTS.md`, `opencode.jsonc`, `.opencode/agents/`, and `.opencode/skills/`.
3. Open an interactive session: `opencode .`
4. Give a complex task — the orchestrator follows the AGENTS.md rules.

For explicit skill execution (recommended for complex multi-step tasks):

```
opencode run --command "omo-orchestrate" "your task description"
```

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

## Example prompts

### Interactive session (`opencode .`)

| Scenario | Prompt |
|----------|--------|
| Simple edit | "Fix the typo in README.md line 12" |
| Code review | "Review the latest changes in src/ for edge cases" |
| Multi-step feature | "Add a retry utility with exponential backoff to src/utils/" |
| Research + implement | "Research the latest React Server Components pattern and apply it to our page component" |

### Headless / scripted (`opencode run`)

```bash
# Explicit orchestration entry point
opencode run --command "omo-orchestrate" \
  "Create an OpenAPI spec parser in lib/ based on the 3.1 spec"

# Direct request (implicit AGENTS.md guidance)
opencode run "Read the first 10 lines of src/config.ts"

# With a specific model
opencode run --model "gemini/gemini-2.5-flash-lite" \
  "Summarize the project's dependency graph"
```

### Session management

```bash
# Continue the last session
opencode -c

# Resume a specific session
opencode -s ses_xxxxxxxxxxxxxxxxxxxxxxxxx

# List all sessions
opencode session list
```

## Customization

- Edit `.opencode/skills/omo-orchestrate/SKILL.md` to modify the pipeline.
- Override model assignments in `opencode.jsonc` → `agent.<name>.model`.
- See `docs/WORKFLOW.md` for a walkthrough.

## Known limitations

| Limitation | Impact | Workaround |
|------------|--------|------------|
| Headless `opencode run` rejects `ask` permissions | `omo-researcher` / `omo-reviewer` subagents cannot auto-delegate in non-interactive mode | Use interactive TUI (`opencode .`) for tasks that need subagent delegation. |
| Skill auto-loading is implicit | `omo-orchestrate` pipeline stages are not explicitly rendered unless loaded via `--command` | Use `opencode run --command "omo-orchestrate"` for explicit stage-by-stage execution. |
| Snapshot glob can miss `.opencode/` | `**/.opencode/skills/**` may return 0 matches in headless mode | Use direct `ls`/`read` instead of glob patterns for `.opencode/` paths. |
| Pipeline timeout on long tasks | Stage 2 (Memory-reader) may time out before completion on first run | Start with a warm-up task, or use `--steps` to increase agent turn limit. |
| Model availability varies | Free-tier models have rate limits and may return Service Unavailable | Configure multiple providers in `~/.config/opencode/opencode.json` for fallback. |

See `docs/TEST_LOG.md` for the full validation report.

## License

MIT
