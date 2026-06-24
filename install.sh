#!/usr/bin/env bash
set -euo pipefail

OMO_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET_DIR=""
GLOBAL=false
DRY_RUN=false
FORCE=false

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Install OMO (Oh-My-Orchestrator) into a project.

Options:
  --target PATH    Install to PATH (default: current directory)
  --global         Install to ~/.config/opencode
  --dry-run        Show what would be done without making changes
  --force          Overwrite existing agents/skills (backup created)
  --help           Show this help message
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      if [ -z "${2:-}" ] || [[ "$2" == -* ]]; then
        echo "Error: --target requires a PATH argument"
        echo "Usage: $0 --target /path/to/project"
        exit 1
      fi
      TARGET_DIR="$2"; shift 2 ;;
    --global)  GLOBAL=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --force)   FORCE=true; shift ;;
    --help|-h) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

if $GLOBAL; then
  TARGET_DIR="${TARGET_DIR:-$HOME/.config/opencode}"
elif [ -z "$TARGET_DIR" ]; then
  TARGET_DIR="$PWD"
fi

if [ ! -f "$OMO_SOURCE_DIR/AGENTS.md" ]; then
  echo "Error: OMO source not found at $OMO_SOURCE_DIR"
  echo "install.sh must be run from the OMO repository root."
  exit 1
fi

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$TARGET_DIR/.omo-backup/$TIMESTAMP"

FILES_AGENTS=(
  ".opencode/agents/omo-researcher.md"
  ".opencode/agents/omo-reviewer.md"
)
DIRS_SKILLS=(
  ".opencode/skills/omo-memory"
  ".opencode/skills/omo-orchestrate"
  ".opencode/skills/omo-web-rag"
)
OMO_MARKER_START='<!-- OMO:BEGIN -->'
OMO_MARKER_END='<!-- OMO:END -->'

echo "============================================"
echo " OMO Installer v0.1.2-dev"
echo "============================================"
echo " Source : $OMO_SOURCE_DIR"
echo " Target : $TARGET_DIR"
$DRY_RUN && echo " Mode   : dry-run (no changes will be made)"
echo ""

# ── Check existing files ──────────────────────
existing_agents_skills=()
for f in "${FILES_AGENTS[@]}"; do
  [ -e "$TARGET_DIR/$f" ] && existing_agents_skills+=("$TARGET_DIR/$f")
done
for d in "${DIRS_SKILLS[@]}"; do
  [ -d "$TARGET_DIR/$d" ] && existing_agents_skills+=("$TARGET_DIR/$d")
done
has_agents_md=false
[ -f "$TARGET_DIR/AGENTS.md" ] && has_agents_md=true

if [ ${#existing_agents_skills[@]} -gt 0 ] && ! $FORCE; then
  echo "Error: Existing agents/skills found. Use --force to overwrite:"
  for f in "${existing_agents_skills[@]}"; do echo "  $f"; done
  echo ""
  echo "Note: AGENTS.md alone does not require --force (marker merge is safe)."
  exit 1
fi

# ── Backup ────────────────────────────────────
if ! $DRY_RUN; then
  # Backup agents/skills only when --force (they get overwritten)
  if $FORCE && [ ${#existing_agents_skills[@]} -gt 0 ]; then
    echo "Creating backup at $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    for f in "${FILES_AGENTS[@]}"; do
      [ -f "$TARGET_DIR/$f" ] && mkdir -p "$BACKUP_DIR/$(dirname "$f")" && cp "$TARGET_DIR/$f" "$BACKUP_DIR/$f"
    done
    for d in "${DIRS_SKILLS[@]}"; do
      [ -d "$TARGET_DIR/$d" ] && mkdir -p "$BACKUP_DIR/$(dirname "$d")" && cp -r "$TARGET_DIR/$d" "$BACKUP_DIR/$d"
    done
    echo ""
  fi
  # Always backup AGENTS.md before merge if it exists
  if $has_agents_md; then
    echo "Backing up AGENTS.md to $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    cp "$TARGET_DIR/AGENTS.md" "$BACKUP_DIR/AGENTS.md"
    echo ""
  fi
fi

# ── Install agents ────────────────────────────
echo "Installing agents..."
for f in "${FILES_AGENTS[@]}"; do
  dest="$TARGET_DIR/$f"
  if $DRY_RUN; then
    echo "  [copy] $f"
  else
    mkdir -p "$(dirname "$dest")"
    cp "$OMO_SOURCE_DIR/$f" "$dest"
    echo "  $f"
  fi
done
echo ""

# ── Install skills ────────────────────────────
echo "Installing skills..."
for d in "${DIRS_SKILLS[@]}"; do
  dest="$TARGET_DIR/$d"
  if $DRY_RUN; then
    echo "  [copy] $d/"
  else
    # Remove first to prevent nested directory on reinstall
    rm -rf "$dest"
    mkdir -p "$(dirname "$dest")"
    cp -r "$OMO_SOURCE_DIR/$d" "$dest"
    echo "  $d/"
  fi
done
echo ""

# ── Install AGENTS.md (marker-based merge) ────
echo "Installing AGENTS.md (marker-based merge)..."
dest="$TARGET_DIR/AGENTS.md"

if $DRY_RUN; then
  echo "  [merge] AGENTS.md"
else
  section=$(mktemp)
  echo "$OMO_MARKER_START" > "$section"
  cat "$OMO_SOURCE_DIR/AGENTS.md" >> "$section"
  echo "" >> "$section"
  echo "$OMO_MARKER_END" >> "$section"

  if [ ! -f "$dest" ]; then
    cat > "$dest" << 'EOF'
# OpenCode Project Configuration

This file inherits from `~/.config/opencode/AGENTS.md`.
Project-local rules and OMO orchestrator configuration go here.

EOF
    cat "$section" >> "$dest"
    echo "  AGENTS.md: created with OMO section"
  else
    mapfile -t lines < "$dest"
    start_idx=-1
    end_idx=-1
    for i in "${!lines[@]}"; do
      if [[ "${lines[$i]}" == "$OMO_MARKER_START" ]]; then start_idx=$i; fi
      if [[ "${lines[$i]}" == "$OMO_MARKER_END" ]]; then end_idx=$i; fi
    done

    if [ $start_idx -ge 0 ] && [ $end_idx -gt $start_idx ]; then
      {
        for ((i=0; i<start_idx; i++)); do echo "${lines[$i]}"; done
        cat "$section"
        for ((i=end_idx+1; i<${#lines[@]}; i++)); do echo "${lines[$i]}"; done
      } > "${dest}.new"
      mv "${dest}.new" "$dest"
      echo "  AGENTS.md: updated existing OMO section"
    else
      {
        cat "$dest"
        echo ""
        cat "$section"
      } > "${dest}.new"
      mv "${dest}.new" "$dest"
      echo "  AGENTS.md: appended OMO section"
    fi
  fi
  rm -f "$section"
fi
echo ""

# ── opencode.jsonc message ────────────────────
echo "Note: opencode.jsonc requires manual integration."
echo ""
echo "  OMO's opencode.jsonc defines agents (omo-researcher, omo-reviewer)"
echo "  and skill permissions. Copy the relevant sections from:"
echo ""
echo "    $OMO_SOURCE_DIR/opencode.jsonc"
echo ""
echo "  into your project's opencode.jsonc (or create one)."
echo "  Automatic merge is not supported in v0.1."
echo ""

# ── Done ──────────────────────────────────────
if ! $DRY_RUN; then
  echo "============================================"
  echo " OMO installation complete!"
  echo "============================================"
  echo ""
  echo "Start an interactive session:"
  echo ""
  echo "  opencode ."
  echo ""
  echo "Or use explicit orchestration:"
  echo ""
  echo "  opencode run --command \"omo-orchestrate\" \"your task\""
  echo ""
fi
