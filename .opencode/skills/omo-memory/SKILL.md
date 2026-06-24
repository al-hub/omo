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

### 5. When to use this skill

Call this skill when:
- Starting a complex task (load past context)
- Completing a significant stage (save checkpoint)
- Finishing a task (save summary)

Do NOT use this skill for:
- Temporary notes that are only relevant to the current conversation
- Content that belongs in source code or documentation
