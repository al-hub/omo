# OMO — Oh-My-Orchestrator

OpenCode 전용 **multi-agent orchestration layer**입니다.
Markdown 기반의 agent 정의, skill workflow, flat-file memory를 조합하여
복잡한 소프트웨어 엔지니어링 작업을 추적 가능한 파이프라인으로 실행합니다.

> OMO를 프로젝트에 추가하면, 기본 build agent가 orchestrator 역할을 수행하고,
> 복잡한 요청을 scout → memory → web-rag → plan → handoff → implement → checkpoint → review → summary
> 의 9단계로 나누어 처리합니다.

---

## Who is this for

- **OpenCode 사용자** — 복잡한 다중 파일 작업을 구조화하고 싶은 사람
- **AI 보조 코딩을 체계화하려는 팀** — 작업 내역을 추적 가능한 문서로 남기고 싶은 팀
- **소형/무료 모델로 최대 효율을 원하는 개발자** — 계산 집약적 작업은 큰 모델에, 단순 작업은 작은 모델에 분배
- **OpenCode 확장 개발자** — skill/agent 시스템의 실제 사용 예시를 참고하려는 사람

---

## Quick start

```bash
# 1. OMO를 프로젝트에 추가 (install.sh 권장)
git clone https://github.com/al-hub/omo.git && cd omo
./install.sh --target /path/to/your/project

# 2. OpenCode 세션 시작
opencode .

# 3. 복잡한 작업을 요청
# → orchestrator가 자동으로 9단계 파이프라인을 실행합니다
```

명시적 pipeline 실행이 필요하다면:

```bash
opencode run --command "omo-orchestrate" \
  "Create an OpenAPI spec parser in lib/"
```

## Prerequisites

- [OpenCode](https://opencode.ai) CLI v1.17+ installed
- 하나 이상의 LLM provider가 `~/.config/opencode/opencode.json`에 설정되어 있어야 함
- (선택) GitHub CLI `gh` — release note 생성에 사용

## Installation

OMO는 **설치형 패키지가 아닌 설정 팩**입니다.
다음 중 하나의 방식으로 프로젝트에 적용하세요.

### A. install.sh (권장)

단일 Bash 스크립트로 agents, skills, AGENTS.md를 자동 설치합니다.

```bash
git clone https://github.com/al-hub/omo.git && cd omo
./install.sh --target /path/to/your/project
```

자세한 옵션은 [docs/INSTALLER.md](./docs/INSTALLER.md)를 참고하세요.

### B. Git subtree / submodule

```bash
git subtree add --prefix .omo https://github.com/al-hub/omo.git main --squash
# 또는
git submodule add https://github.com/al-hub/omo.git .omo
```

### C. git archive (ZIP 배포)

git clone 없이 특정 버전만 ZIP 파일로 받아 설치할 수 있습니다.

```bash
# GitHub Release 페이지에서 omo.zip 다운로드 후
unzip omo.zip -d /tmp/omo && cd /tmp/omo
./install.sh --target /path/to/your/project
```

### D. 직접 복사

```bash
# omo 레포를 클론한 후, 필요한 파일만 복사
cp -r AGENTS.md opencode.jsonc .opencode/ docs/ <target-project>/
```

### E. 수동 통합

프로젝트에 이미 `AGENTS.md`나 `opencode.jsonc`가 있다면,
OMO의 설정을 참고하여 필요한 부분만 병합하세요.

> **Note**: OMO는 전역 `~/.config/opencode/` 설정과 병합되어 동작합니다.
> 프로젝트 로컬 설정이 전역 설정보다 우선합니다.

## Structure

```
OMO/
├── AGENTS.md              Orchestrator rules (project-level)
├── opencode.jsonc         Agent registration & permissions
├── .opencode/
│   ├── agents/            Subagent definitions (researcher, reviewer)
│   ├── skills/            Skill packs (orchestrate, memory, web-rag)
│   └── memory/            Persistent flat-file memory (auto-generated)
├── docs/                  Architecture, workflow & roadmap
├── CHANGELOG.md           Release history
└── LICENSE                MIT
```

## How it works

OMO는 하나의 **entry skill**(`omo-orchestrate`)을 중심으로 동작합니다.

```
┌─ build agent (orchestrator) ──────────────────────────┐
│  AGENTS.md rules → skill 로드 → 9-stage pipeline      │
│  각 단계 완료 시 .opencode/memory/ 에 artifact 기록    │
│  subagent는 skill 지시가 있을 때만 task()로 호출       │
└───────────────────────────────────────────────────────┘
         │ loads
         ▼
┌─ omo-orchestrate skill ───────────────────────────────┐
│  1. Intake         (단순/복합 판단)                     │
│  2. Local-scout    (코드베이스 탐색 → scout-*.md)      │
│  3. Memory-reader  (과거 맥락 로드 → omo-memory skill) │
│  4. Web-RAG        (조건부: 외부 정보 필요시)          │
│  5. Plan           (실행 계획 → plan-*.md)             │
│  6. Handoff        (3+ 파일 작업 → handoff-*.md)       │
│  7. Implement      (코드 작성)                         │
│  8. Checkpoint     (검증 → checkpoint-*.md)            │
│  9. Test & Review  (리뷰어 호출 → review-*.md)         │
│ 10. Summary        (요약 → summary-*.md, memory 저장)  │
└───────────────────────────────────────────────────────┘
```

### Component roles

| Component | Type | Role |
|-----------|------|------|
| `omo-orchestrate` | skill (entry) | Workflow pipeline definition |
| `omo-memory` | skill (support) | Read/write/search `.opencode/memory/` |
| `omo-web-rag` | skill (support) | Lightweight internet research workflow |
| `omo-researcher` | subagent | Deep web RAG (fallback: when web-rag is insufficient) |
| `omo-reviewer` | subagent | Code review via `git diff` |

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

## Roadmap

| Milestone | Focus |
|-----------|-------|
| v0.1 (MVP) | Skill-centered orchestration, flat-file memory, 2 subagents |
| v0.2 | Multi-session memory merge, web-rag result caching |
| v0.3 | Plugin-based custom stage support, template projects |
| v1.0 | Stable API, full test coverage, CI validation |

See [docs/ROADMAP.md](./docs/ROADMAP.md) for details.

## Changelog

- **v0.1.0** (2026-06-24) — MVP release. See [CHANGELOG.md](./CHANGELOG.md).

## License

MIT
