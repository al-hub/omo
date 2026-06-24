# OMO Roadmap

## v0.1 — MVP (current) ✅

**Focus**: Basic orchestration structure, flat-file memory, minimal subagents.

- [x] `omo-orchestrate` entry skill with 9-stage pipeline
- [x] `omo-memory` skill (CRUD on `.opencode/memory/`)
- [x] `omo-web-rag` skill (lightweight internet research)
- [x] `omo-researcher` subagent (deep web RAG)
- [x] `omo-reviewer` subagent (code review)
- [x] AGENTS.md rules (orchestrator identity, memory convention, model discipline)
- [x] opencode.jsonc configuration (agent registration, permissions, skill control)
- [x] Test log and validation (docs/TEST_LOG.md)
- [x] Public-ready documentation (README, ARCHITECTURE, WORKFLOW, CHANGELOG)

---

## v0.2 — Memory & RAG enhancements

**Focus**: Make memory persistent across sessions, improve research quality.

- [ ] **Multi-session memory merge**: When resuming, automatically merge summaries from past sessions into current context
- [ ] **Web-RAG result caching**: Avoid re-fetching the same URL within a configurable TTL
- [ ] **Research depth control**: `--quick` / `--deep` flag for web-rag skill
- [ ] **Memory pruning**: Auto-archive memory files older than N days
- [ ] **Handoff template**: Standardized handoff.md format with checklist

---

## v0.3 — Extensibility

**Focus**: Make the pipeline customizable without editing core skills.

- [ ] **Custom stage hooks**: Allow projects to inject their own stage between existing stages
- [ ] **Template projects**: `omo init` — generate a starter `.opencode/` for a new project
- [ ] **Stage gating**: Skip stages based on file patterns (e.g., skip web-rag for pure config changes)
- [ ] **Agent prompt customization**: Per-project prompt overrides via `opencode.jsonc`

---

## v1.0 — Stable

**Focus**: Production readiness.

- [ ] **Full test coverage**: Test every stage and subagent interaction
- [ ] **CI validation**: GitHub Actions that validate config + run scenario tests
- [ ] **Migration guide**: Clear upgrade path from v0.x
- [ ] **Multi-repo support**: Orchestrate across multiple repositories in one session
- [ ] **Performance benchmarks**: Token usage and latency measurements per stage

---

## Beyond v1.0

- Vector-based memory (embedding search over flat files)
- Plugin SDK for custom stages (TypeScript)
- Web UI for pipeline visualization
- Remote agent delegation (orchestrate across machines)
