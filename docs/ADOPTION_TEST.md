# OMO Adoption Test Plan

## 1. Test purpose

OMO v0.1.0이 **실제 다른 프로젝트**에서 의도한 대로 동작하는지 검증한다.
자기 자신(OMO repo)이 아니라 별도의 작은 코드 repo에 OMO를 설치/통합하여,
일반적인 소프트웨어 엔지니어링 작업에서 orchestration pipeline이 정상 동작하는지 확인한다.

**검증 범위**:
- Config/agent/skill이 OpenCode에 의해 정상 로드되는가
- 단순 작업은 직접 처리하고, 복합 작업은 pipeline을 따르는가
- Memory/handoff/checkpoint 파일이 실제로 생성되는가
- Subagent 호출이 설계 의도(과하지 않음)대로 이루어지는가
- 실제 사용 시 예상치 못한 장애 지점은 없는가

---

## 2. Test target repo conditions

아래 조건을 충족하는 repo를 테스트 대상으로 선정한다.

| 조건 | 이유 |
|------|------|
| 외부 GitHub public repo | 실제 사용 환경 재현 |
| 500줄 이상의 코드 | 단순 Toy project 제외 |
| 최소 1개 이상의 의존성 | RAG 시나리오 테스트 가능 |
| TypeScript 또는 Python | 널리 사용되는 언어 |
| 테스트 명령어 존재 (`npm test` or `pytest`) | review 시나리오에서 실행 가능 |
| OMO 미적용 상태 | 신규 도입 과정 검증 |

**권장 후보**:
- 작은 CLI 도구 (commander/click 기반)
- 단순 API 서버 (Express/FastAPI)
- 유틸리티 라이브러리 (lodash 스타일)

---

## 3. Installation method

설치 방식은 `git subtree add`를 사용한다.
이는 OMO가 사용하는 프로젝트와 독립적으로 버전 관리되도록 하기 위함이다.

```bash
# 대상 repo에서 실행
git subtree add --prefix .omo https://github.com/al-hub/omo.git v0.1.0 --squash
```

설치 후 확인 사항:
- [ ] `.omo/AGENTS.md`가 프로젝트 루트에 복사되었는가?
- [ ] `.omo/opencode.jsonc`가 프로젝트 루트에 복사되었는가?
- [ ] `.omo/.opencode/agents/`가 존재하는가?
- [ ] `.omo/.opencode/skills/`에 3개 skill 디렉토리가 존재하는가?
- [ ] `.omo/.opencode/memory/`가 존재하는가?
- [ ] `opencode agent list`에 `omo-researcher`, `omo-reviewer`가 보이는가?

> **Note**: subtree add는 prefix 내부 파일만 복사하므로,
> `AGENTS.md`와 `opencode.jsonc`는 대상 repo 루트로 **수동 복사**해야 할 수 있다.
> 이 경우 설계 단계에서 이슈로 기록한다.

---

## 4. Test scenarios

### Scenario A — Local-only bugfix

**목적**: 순수 로컬 코드 수정에서 OMO가 불필요한 orchestration을 수행하지 않는지 확인.

**프롬프트 예시**:
```
src/utils/formatDate.ts의 변수명 오타를 수정해줘
```

**예상 동작**:
- build agent가 AGENTS.md의 "단순 작업 판단" 기준에 따라 직접 수정
- `omo-orchestrate` skill 미호출
- `.opencode/memory/`에 artifact 생성되지 않음 (또는 최소한)

**성공 기준**:
- [ ] 1-2 step 이내에 수정 완료
- [ ] 코드 변경이 정확함
- [ ] 불필요한 memory/handoff/checkpoint 파일 없음

---

### Scenario B — Web/RAG required task

**목적**: 새로운 라이브러리나 API를 도입할 때 RAG workflow가 동작하는지 확인.
이 시나리오는 OMO pipeline의 **전체 9개 stage를 모두 검증**합니다.

#### Test target 조건

| 조건 | 설명 |
|------|------|
| 언어 | TypeScript/JavaScript (npm test 가능) |
| 기존 zod 사용 | `package.json`에 `zod` 의존성이 있고, `import { z } from "zod"` 패턴 사용 |
| 테스트 가능 | `npm test` 또는 `npm run test` 통과 |

**권장 후보**: 작은 Express/Fastify API 서버, CLI 도구, 유틸리티 라이브러리

#### 실행 절차

**준비 단계 (tester)**:

```bash
# 1. 대상 repo 클론
git clone <target-repo-url> /tmp/adopt-b
cd /tmp/adopt-b

# 2. OMO 설치 (install.sh 사용)
/path/to/omo/install.sh --target /tmp/adopt-b

# 3. 기존 테스트 통과 확인
npm test
# → PASS 여부 기록

# 4. OpenCode 세션 시작
opencode .
```

**요청**:

```
최신 zod v4 릴리즈 노트를 확인하고, 변경된 API를 반영한 마이그레이션 유틸을 src/migration/ 아래에 만들어줘. src/ 디렉토리가 없으면 만들고, 패턴은 기존 zod import 방식을 참고해.
```

#### 관찰 포인트 (stage별)

| Stage | 관찰할 것 | 기대 동작 |
|-------|-----------|-----------|
| 0 | 복합 작업 판단 메시지 | "task requires orchestration" 또는 유사 메시지 |
| 1 | scout-*.md 생성 | 파일 읽기 + 패턴 분석 |
| 2 | memory-reader 동작 | 이전 memory 확인 (없으면 "no prior context") |
| 3 | **web-search 호출** | "zod v4 release notes" 검색 |
| 3 | **web-fetch 호출** | 실제 URL fetch |
| 3 | research-*.md 생성 | topic, sources, key findings 포함 |
| 4 | plan-*.md 생성 | Goal, Approach, Files, Steps, Risks 포함 |
| 5 | handoff-*.md 생성 | task summary, decisions, files, pitfalls 포함 |
| 6 | 코드 구현 | src/migration/ 아래에 파일 생성 |
| 7 | checkpoint-*.md 생성 | file_check, syntax_check, quick_test 결과 |
| 7 | syntax check 실행 | npx tsc --noEmit 또는 npm test --dry-run |
| 8 | 테스트 실행 | npm test 통과 |
| 8 | review-*.md 생성 | reviewer 호출 시에만 |
| 9 | summary-*.md 생성 | what was done, learned 포함 |

#### 체크리스트

- [ ] **Stage 0**: 복합 작업 자동 판단
- [ ] **Stage 1**: scout-*.md 파일 생성됨
- [ ] **Stage 2**: memory-reader 실행 (또는 skip)
- [ ] **Stage 3**: web-search 1회 이상 호출됨
- [ ] **Stage 3**: web-fetch 1회 이상 호출됨
- [ ] **Stage 3**: research-*.md 파일 생성됨 (topic, sources, key findings 포함)
- [ ] **Stage 4**: plan-*.md 파일 생성됨 (6개 필수 항목 포함)
- [ ] **Stage 5**: handoff-*.md 파일 생성됨 (6개 필수 섹션 포함)
- [ ] **Stage 6**: src/migration/ 아래에 실제 코드 생성됨
- [ ] **Stage 7**: checkpoint-*.md 파일 생성됨 (file/syntax/test check 포함)
- [ ] **Stage 7**: syntax check 자동 실행
- [ ] **Stage 8**: npm test 통과
- [ ] **Stage 9**: summary-*.md 파일 생성됨
- [ ] **전체**: 6개 이상 artifact 파일 생성 (scout, research, plan, handoff, checkpoint, summary)
- [ ] **전체**: subagent 호출이 필요 이상으로 많지 않음 (researcher는 0-1회)
- [ ] **전체**: 최종 코드가 실제로 동작함 (테스트 통과)

#### 데이터 기록 양식

```yaml
scenario: B
target_repo: <url>
target_language: TypeScript
omo_version: v0.1.1-dev
date: <YYYY-MM-DD>
duration_minutes: <int>
stage_count: <int>  # 실행된 stage 수 (1-9)
artifact_count: <int>  # 생성된 artifact 파일 수
web_search_count: <int>  # websearch 호출 횟수
web_fetch_count: <int>  # webfetch 호출 횟수
subagent_calls: <int>  # task() 호출 횟수
iterations: <int>  # Stage 6↔7 loop 횟수
result: pass | fail
fail_stage: <number> | null
notes: <string>
```

---

### Scenario C — Review-only task

**목적**: 코드 리뷰 요청 시 build agent가 직접 처리하는지, 불필요하게 reviewer subagent를 호출하지 않는지 확인.

**프롬프트 예시**:
```
src/services/api.ts의 최근 변경사항을 리뷰해줘. 보안 취약점이나 에지 케이스가 있는지 확인해줘
```

**예상 동작**:
- build agent가 직접 파일 읽기 + 분석
- `omo-reviewer` subagent 미호출 (Stage 8 코드 리뷰 전용이므로)
- 별도 artifact 생성 없이 응답만 반환

**성공 기준**:
- [ ] 2-3 step 이내에 리뷰 완료
- [ ] 파일 단위 구체적인 피드백 제공
- [ ] subagent 호출 없음

---

### Scenario D — Session continuation

**목적**: Scenario B에서 중단된 세션을 이어서 진행할 수 있는지 확인.

**프롤토콜**:
1. Scenario B를 실행하고, Plan 단계까지만 진행한 후 세션 종료
2. 새 세션에서 `opencode -c`로 재개
3. "이어서 구현 단계부터 진행해줘" 라고 요청

**예상 동작**:
- 이전 session의 context가 로드됨
- plan-*.md 내용이 참조됨
- 구현 단계부터 재개

**성공 기준**:
- [ ] 이전 session ID 확인 가능
- [ ] 재개 후 이전 맥락(plan)을 인지하고 있음
- [ ] 구현이 plan과 일치함
- [ ] memory에 checkpoint/summary가 정상 저장됨

---

## 5. Success criteria

모든 시나리오가 아래 기준을 충족해야 adoption test **PASS**로 간주한다.

| # | 기준 | 측정 방법 |
|---|------|-----------|
| 1 | 모든 시나리오에서 치명적 오류 없음 | OpenCode crash, hang, infinite loop 발생 여부 |
| 2 | 단순 작업에서 orchestration 과호출 없음 | Scenario A: step 수 2 이하, artifact 없음 |
| 3 | 복합 작업에서 full pipeline 실행 | Scenario B: 6개 이상 artifact 파일 생성 |
| 4 | Subagent 호출이 설계 범위 내 | Researcher 미호출 (간단 RAG), Reviewer 미호출 (Scenario C) |
| 5 | Memory 파일이 읽을 수 있는 품질 | YAML frontmatter 정확성, markdown 구조完整性 |
| 6 | Session continuation이 맥락 유지 | 재개 후 이전 결정 사항 인지 |

---

## 6. Metrics to record

각 시나리오에 대해 아래 지표를 기록한다.

### Execution metrics

| 지표 | 설명 | 기록 방법 |
|------|------|-----------|
| 소요 시간 | 첫 요청부터 최종 응답까지 (분) | `date` 로 시작/종료 시간 기록 |
| Step 수 | OpenCode loop step count | 로그의 `step=N` 값 |
| 재지시 횟수 | 사용자가 추가로 지시를 내린 횟수 | 수동 카운트 |
| 사용자 개입 지점 | permission 승인/거부, 방향 수정 시점 | 시나리오 로그에 별도 표시 |

### Artifact quality metrics

| 지표 | 평가 기준 |
|------|-----------|
| plan-*.md | 목표·접근·파일·단계·위험·의존성 6항목 포함? |
| handoff-*.md | 결정 사항, 파일별 작업 내용, pitfalls 명시? |
| checkpoint-*.md | 검증 결과(pass/fail) 명시? |
| review-*.md | verdict + issue list(file:line) 포함? |
| summary-*.md | 완료 작업, 학습 내용, 미해결 질문 포함? |
| research-*.md | source URL, 요약, key findings 포함? |

### Subagent metrics

| 지표 | 기준 |
|------|------|
| Researcher 호출 횟수 | Scenario B에서 1회 이하 권장 |
| Reviewer 호출 횟수 | Scenario C에서 0회 (직접 처리) |
| 불필요 호출 여부 | 설계 의도와 다른 subagent 호출 있었는가 |

---

## 7. Issue reporting format

발견된 모든 이슈는 아래 양식으로 기록한다.

```markdown
---
id: ADOPT-{NN}
scenario: A | B | C | D
severity: critical | major | minor | info
status: open | fixed | wontfix
---

## Description

{간결한 문제 설명}

## Reproduction

1. {재현 단계}
2. {재현 단계}

## Expected behavior

{기대한 동작}

## Actual behavior

{실제 발생한 동작}

## Impact

{사용자에게 미치는 영향}

## Suggested fix

{잠재적 해결 방안, 있으면}
```

---

## Appendix: Test environment

| 항목 | 값 |
|------|-----|
| OMO version | v0.1.0 |
| OpenCode version | |
| Test target repo | |
| Target language | |
| Target test command | |
| Model (build) | |
| Model (researcher) | |
| Model (reviewer) | |
| Date | |
| Tester | |
