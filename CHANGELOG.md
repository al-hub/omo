# Changelog

## v0.1.0 — MVP (2026-06-24)

**OMO (Oh-My-Orchestrator)** 초기 릴리즈.
OpenCode 위에서 동작하는 skill-centered multi-agent orchestration pack입니다.

### Added

- **`AGENTS.md`** — orchestrator 규칙: skill-first, staged checkpoints, traceability
- **`opencode.jsonc`** — 로컬 설정: agent 등록, permission override, skill 권한 제어
- **`.opencode/agents/omo-researcher.md`** — 웹 RAG 전담 subagent
- **`.opencode/agents/omo-reviewer.md`** — 코드 리뷰 전담 subagent
- **`.opencode/skills/omo-orchestrate/SKILL.md`** — 9-stage orchestration pipeline (entry point)
- **`.opencode/skills/omo-memory/SKILL.md`** — flat-file memory CRUD
- **`.opencode/skills/omo-web-rag/SKILL.md`** — lightweight internet RAG workflow
- **`.opencode/memory/`** — persistent artifact 저장소
- **`docs/ARCHITECTURE.md`** — 전체 구조 문서
- **`docs/WORKFLOW.md`** — 사용자 workflow 가이드
- **`docs/ROADMAP.md`** — 향후 계획
- **`docs/TEST_LOG.md`** — MVP 검증 결과
- **`CHANGELOG.md`** — 이 파일

### Validated

- OpenCode v1.17.9에서 config/agent/skill 정상 로드 확인
- 4개 시나리오 테스트 완료 (단순 수정, 복합 작업, 리뷰, 세션 이어가기)
- `--command "omo-orchestrate"`로 명시적 pipeline 실행 확인
- Memory CRUD (.opencode/memory/) 정상 동작 확인

### Known limitations

- Headless 모드에서 `ask` permission 거부 → TUI 사용 권장
- Skill auto-loading이 암시적 → `--command "omo-orchestrate"` 권장
- Snapshot glob이 `.opencode/`를 누락할 수 있음 → `ls`/`read` 우회

### Notes

- 순수 Markdown + JSONC 구성. TypeScript/Python plugin 불필요.
- 무료 모델(gemini-2.5-flash-lite, step-3.5-flash)에서 테스트 완료.
- `~/.config/opencode/`의 전역 설정과 병합되어 동작.
