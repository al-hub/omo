# Handoff Template

handoff는 Stage 5에서 생성되는 artifact로, 구현 단계(Stage 6)의 단일 진실 공급원(Single Source of Truth) 역할을 합니다.
이 문서는 handoff 작성 시 포함해야 할 필수 항목과 형식을 정의합니다.

## File naming

```
.opencode/memory/handoff-{YYYYMMDD}-{seq}.md
```

## Required sections

### YAML frontmatter

```yaml
---
stage: handoff
task: <간결한 작업 설명 (50자 이내)>
timestamp: <ISO8601>
files:
  - <변경할 파일 경로>
  - <변경할 파일 경로>
tags: [tag1, tag2]
---
```

### 1. Task summary

Stage 4 plan의 목표를 1-2문장으로 요약.

### 2. Current codebase state

Stage 1 scout에서 파악한 관련 파일들의 현재 상태.
- 어떤 파일이 존재하는지
- 어떤 패턴을 따르고 있는지
- 주의할 점 (예: 테스트가 깨져있는 상태, 특정 lint 규칙 등)

### 3. Key decisions

Plan 단계에서 내린 주요 결정들.
- 왜 특정 접근 방식을 선택했는지
- 왜 다른 접근을 배제했는지
- 아직 결정되지 않은 사항 (open questions)

### 4. Files to modify

변경할 파일별 상세 작업 지침.

```markdown
#### `path/to/file`

- **작업**: 추가/수정/삭제
- **설명**: 무엇을 변경해야 하는지
- **주의사항**:
  - 이 파일의 특정 convention
  - 다른 파일과의 의존성
  - 에지 케이스
- **검증**: 수정 후 이 파일만 봐서 확인할 수 있는 기준
```

### 5. Pitfalls & gotchas

Scout/Plan 단계에서 발견한 위험 요소나 주의사항.
- 이전 시도에서 실패한 패턴
- 예상치 못한 의존성
- 성능/보안 고려사항

### 6. Verification criteria

구현 완료 후 확인해야 할 사항들.
- 눈으로 확인할 수 있는 것 (파일 존재, 특정 패턴 일치)
- 실행해야 확인할 수 있는 것 (테스트 명령어, lint 명령어)
- 수동 확인이 필요한 것

## Example

```yaml
---
stage: handoff
task: Add circular dependency detection to install.sh
timestamp: 2026-06-24T22:00:00Z
files:
  - install.sh
tags: [bash, install, dependency]
---
```

### 1. Task summary

install.sh의 `install_package` 함수에 circular dependency 감지 로직을 추가하여,
동일 패키지가 의존성 체인에 두 번 등장하면 경고하고 중단한다.

### 2. Current codebase state

- `install.sh`는 ~300줄의 bash 스크립트
- `install_package` 함수는 재귀적으로 의존성을 설치
- 현재 circular dependency 감지 로직이 없어 무한 재귀 가능
- `bash -n install.sh`로 문법 검증 가능

### 3. Key decisions

- `seen` 배열을 사용한 방문 체크 (hash set 대신 bash 배열)
- 에러 메시지 출력 후 `exit 1` (soft warning보다 hard fail)
- 의존성 그래프 전체 탐색이 아닌, 설치 경로상의 중복만 감지

### 4. Files to modify

#### `install.sh`

- **작업**: 수정
- **설명**: `install_package` 함수 진입 시 `seen` 배열에 패키지 추가,
  중복 발견 시 메시지 출력 후 `exit 1`
- **주의사항**:
  - `seen` 배열은 함수 로컬이 아닌 전역으로 선언해야 caller도 확인 가능
  - `is_done` 체크는 stack_contains 이후에 실행되어야 함
- **검증**: `bash -n install.sh` 통과, circular test 통과

### 5. Pitfalls & gotchas

- `stack_pop` 순서가 잘못되면 감지 실패 → pop 전에 검사할 것
- 로그 메시지만 바꾸고 로직을 수정하지 않는 실수 주의

### 6. Verification criteria

- [ ] `bash -n install.sh` 통과
- [ ] Circular dependency test 통과
- [ ] Non-circular dependency test 통과
- [ ] 기존 정상 설치 시나리오에 영향 없음
