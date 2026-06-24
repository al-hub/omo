# OMO Installer

`install.sh`는 OMO를 다른 프로젝트에 쉽게 적용할 수 있도록 도와주는 Bash 기반 설치 도구입니다.

## Quick start

```bash
# OMO 레포지토리 루트에서 실행
./install.sh

# 또는 원하는 대상에 직접 설치
./install.sh --target /path/to/your/project
```

## Options

| Option | Description |
|--------|-------------|
| `--target PATH` | 설치 대상 디렉토리 (기본값: 현재 디렉토리) |
| `--global` | `~/.config/opencode`에 설치 (전역 설정) |
| `--dry-run` | 실제 변경 없이 설치될 내용만 출력 |
| `--force` | 기존 agents/skills 덮어쓰기 허용 (AGENTS.md는 --force 불필요) |
| `--help` | 사용법 출력 |

> AGENTS.md는 --force 없이도 marker 병합이 가능합니다. agents/skills 파일이 이미 있을 때만 --force가 필요합니다.

## What gets installed

### Agents (`.opencode/agents/`)

| File | Purpose |
|------|---------|
| `omo-researcher.md` | Deep web RAG research subagent |
| `omo-reviewer.md` | Code review subagent |

### Skills (`.opencode/skills/`)

| Directory | Purpose |
|-----------|---------|
| `omo-memory/` | Flat-file memory CRUD |
| `omo-orchestrate/` | 9-stage orchestration pipeline (entry point) |
| `omo-web-rag/` | Lightweight internet RAG workflow |

### AGENTS.md

install.sh는 AGENTS.md를 **절대 통째로 덮어쓰지 않습니다**. 대신 marker 기반 병합을 수행합니다.

- `<!-- OMO:BEGIN -->` / `<!-- OMO:END -->` 마커가 이미 있으면 **내용만 갱신**
- 마커가 없으면 **파일 끝에 섹션 추가**
- 파일이 없으면 **새로 생성**

### opencode.jsonc

v0.1에서는 opencode.jsonc를 자동 병합하지 않습니다. 설치 완료 후 안내 메시지를 따라 수동으로 병합하세요.

## Examples

### Dry-run (변경 없이 확인)

```bash
./install.sh --target ~/projects/my-app --dry-run
```

### 대상 지정 설치

```bash
./install.sh --target ~/projects/my-app
```

### 기존 파일 덮어쓰기

```bash
./install.sh --target ~/projects/my-app --force
```

`--force`를 사용하면 기존 agents/skills가 `.omo-backup/YYYYMMDD-HHMMSS/`에 백업됩니다.
AGENTS.md는 --force와 관계없이 항상 병합 전 백업됩니다.

### AGENTS.md만 있는 프로젝트

```bash
# agents/skills가 없고 AGENTS.md만 있으면 --force 불필요
./install.sh --target ~/projects/my-app
```

이 경우 AGENTS.md는 marker 병합되고, agents/skills는 신규 설치됩니다.

### 전역 설치

```bash
./install.sh --global
```

`~/.config/opencode/` 아래에 OMO 설정이 설치됩니다.

## After installation

```bash
# Interactive session
opencode .

# Explicit orchestration
opencode run --command "omo-orchestrate" "your task"
```

## Manual installation (without install.sh)

install.sh를 사용할 수 없는 환경에서는 수동으로 파일을 복사할 수 있습니다.

```bash
# OMO 레포에서 대상 프로젝트로 복사
cp -r .opencode/agents /path/to/project/.opencode/
cp -r .opencode/skills /path/to/project/.opencode/
```

AGENTS.md는 수동으로 marker 섹션을 추가하거나, 파일 내용을 적절히 병합하세요.

## Distribution via git archive

OMO를 ZIP/Tarball로 배포해야 한다면 `git archive`를 사용하세요.

```bash
# 최신 릴리즈를 ZIP으로打包
git archive --format=zip --output=omo.zip v0.1.0

# 또는 압축 해제 후 install.sh 실행
unzip omo.zip -d /tmp/omo && cd /tmp/omo
./install.sh --target ~/projects/my-app
```

`git archive`는 `.gitignore`에 명시된 불필요한 파일(node_modules 등)을 제외하고
필요한 파일만 깔끔하게打包합니다.
