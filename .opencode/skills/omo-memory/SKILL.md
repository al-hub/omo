---
name: omo-memory
description: Read, write, and search project memory in .opencode/memory/. Use for loading past context and persisting new information.
compatibility: opencode
metadata:
  stage: support
  workflow: memory
---

# OMO Memory — Persistent Context Management

This skill provides standardized operations for project memory stored as flat markdown files in `.opencode/memory/`.

## File format

Every memory file starts with YAML frontmatter:

```yaml
---
stage: scout|plan|checkpoint|review|summary|research
task: <brief description>
timestamp: <ISO8601>
tags: [tag1, tag2]
---
```

## Operations

### 1. List memory files

```
ls .opencode/memory/
```

Read the `stage` and `task` from the frontmatter of each file (first 5 lines).

### 2. Search memory

Use `grep` to find relevant files:

```
rg -l "<keyword>" .opencode/memory/
```

Then read the top 1-3 matches.

### 3. Read a specific file

```
read .opencode/memory/<filename>
```

### 4. Save to memory

Create a new file with the naming convention:

```
.opencode/memory/{stage}-{YYYYMMDD}-{seq}.md
```

Where `{seq}` is a 2-digit sequence number (01, 02, ...) to avoid collisions.

The file must include YAML frontmatter and markdown body.

### 5. Prune old memory

Move aged memory files to `archive/` to keep working memory focused.

**TTL rules:**
- Default: **14 days** (files older than 14 days are archived)
- Tag `ephemeral`: **7 days** (short-lived context)
- Tag `permanent`: never pruned (config, templates, reference)

**Procedure:**

1. List all files in `.opencode/memory/` (not in `archive/` subdirectory)
2. For each file, read the YAML frontmatter to get `timestamp` and `tags`
3. Parse the timestamp (ISO 8601) and compare with current date
4. If the file has tag `permanent`, skip it
5. If the file has tag `ephemeral` and is older than 7 days, move it:
   ```
   mkdir -p .opencode/memory/archive/
   mv .opencode/memory/{file} .opencode/memory/archive/{file}
   ```
6. Otherwise, if older than 14 days, move it:
   ```
   mv .opencode/memory/{file} .opencode/memory/archive/{file}
   ```

**When to prune:**
- Before saving a new summary (Stage 9)
- Before loading context for a new task (Stage 2)
- Skip pruning during active task execution to avoid disrupting in-progress artifacts

### 6. Merge memories

Combine multiple past summaries into a single context object for session resume.

**When to merge:**
- Starting a new session after a previous session completed (detected by existing `summary-*.md` files)
- Before loading context for a complex task (Stage 2)

**Procedure:**

1. List all `summary-*.md` and `research-*.md` files in `.opencode/memory/` (not in `archive/`)
2. Sort by `timestamp` descending (newest first)
3. Select the top 5 most recent files
4. For each file, read the full content and extract:
   - `stage` and `task` from YAML frontmatter
   - "What was done" section (for summaries)
   - "What was learned" section (for summaries)
   - "Key findings" section (for research files)
5. Combine into a single context with this structure:

```
## Previous session context

### Most recent session: <task> (<timestamp>)
<what was done> / <key findings>

### Prior session: <task> (<timestamp>)
<what was done> / <key findings>
...
```

6. If there is a `handoff-*.md` file with matching `task` that is still open (no corresponding `summary-*.md`), include it as "in-progress context"

**Deduplication rules:**
- If two summary files describe the same task (matching by `task` field), keep only the newer one
- If a summary and research file cover the same topic, prefer the summary (it's more synthesized)
- Skip files tagged `ephemeral` (they were intentionally short-lived)

### 7. When to use this skill

Call this skill when:
- Starting a complex task (load past context)
- Completing a significant stage (save checkpoint)
- Finishing a task (save summary)

Do NOT use this skill for:
- Temporary notes that are only relevant to the current conversation
- Content that belongs in source code or documentation
