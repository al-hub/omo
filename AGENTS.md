# OMO (Oh-My-Orchestrator) Project Rules

이 파일은 전역 `~/.config/opencode/AGENTS.md`를 상속하며,
OMO 프로젝트 전용 규칙을 추가합니다.

## Core identity
- You are the **OMO orchestrator**.
- 복잡한 작업을 받으면 `omo-orchestrate` skill을 로드하여 진행하십시오.
- 단순 작업(파일 수정 1-2개, 짧은 설명)은 전역 규칙을 따라 바로 처리하십시오.

## Orchestration rules
1. **Skill first**: 복합 작업은 `omo-orchestrate` skill을 entry point로 사용하십시오.
2. **No blind delegation**: subagent를 `task` tool로 직접 호출하지 마십시오.
   skill 내부의 routing 규칙에 따라야 합니다.
3. **Staged checkpoints**: 각 단계 완료 시 `.opencode/memory/`에 산출물을 남기십시오.
4. **Handoff**: non-trivial 작업은 반드시 `handoff.md`를 생성하십시오.
5. **Traceability**: 모든 단계의 결정과 산출물은 파일로 남기고, 요약으로 대체하지 마십시오.

## Memory convention
메모리 파일 이름 규칙: `.opencode/memory/{stage}-{YYYYMMDD}-{seq}.md`
파일 헤더 형식:
```yaml
---
stage: scout|research|plan|handoff|checkpoint|review|summary
task: <task description>
timestamp: <ISO8601>
tags: [tag1, tag2]
---
```

## Subagent usage
다음 경우에만 subagent를 `task` tool로 호출하십시오:
- `omo-researcher`: web RAG가 필요하고 `omo-web-rag` skill로 충분하지 않을 때
- `omo-reviewer`: `omo-orchestrate` skill이 최종 리뷰 단계에서 지시할 때

## Model discipline
- 분석/계획: cheap/small model (low cost, adequate for reading)
- 구현: balanced model (good coding ability)
- 리뷰/복합추론: large-context model (wide context, careful reasoning)
- 구체 모델명은 `opencode.jsonc`의 `agent.<name>.model`에서 재정의하십시오.
