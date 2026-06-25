---
name: omo-orchestrate
description: Master orchestration entry point. Routes complex tasks through scout → memory → web-rag → plan → handoff → implement → checkpoint → review → summary pipeline.
compatibility: opencode
metadata:
  stage: entry
  workflow: orchestration
---

# OMO Orchestrate — Standard Workflow

You are the OMO orchestrator. Follow this workflow for any non-trivial task.

## Stage 0: Intake

Receive the user's request. Determine:
- Is this trivial (1-2 files, known pattern)? → Skip orchestration, handle directly per global rules.
- Is this complex (multi-file, new domain, uncertain)? → Begin Stage 1.

## Stage 1: Local-scout

Explore the codebase to understand current state relevant to the task.

```
Artifact: .opencode/memory/scout-{YYYYMMDD}-{seq}.md
```

- Use `glob`, `grep`, and `read` to find relevant files.
- Document: which files exist, what they do, what patterns they follow.
- If the project has tests, lint config, or typecheck config, note them.
- Keep this stage under 1 page. Do NOT exhaustively read everything.

## Stage 2: Memory-reader (via omo-memory skill)

Load relevant past context from `.opencode/memory/`.

1. Load `omo-memory` skill: `skill({ name: "omo-memory" })`
2. Follow its instructions to:
   - List existing memory files with `ls .opencode/memory/`
   - Grep for keywords matching the current task
   - Read the most relevant 1-3 files
3. If no relevant memory found, note "no prior context".

## Stage 3: Web-RAG (conditional)

Decide: does this task need external information?
- New library/framework? → Yes
- Latest API or version? → Yes
- Standard algorithm in familiar language? → No

If yes:
1. Load `omo-web-rag` skill: `skill({ name: "omo-web-rag" })`
2. Follow its instructions to search, fetch, and summarize.
3. If the research scope is very large or ambiguous, delegate to `omo-researcher` subagent via `task()`.

If no: skip this stage.

## Stage 4: Plan

Synthesize everything so far into an execution plan.

```
Artifact: .opencode/memory/plan-{YYYYMMDD}-{seq}.md
```

Include:
- **Goal**: one-sentence restatement
- **Approach**: high-level strategy
- **Files to create/modify**: list with brief description per file
- **Steps**: numbered, ordered
- **Risks**: anything uncertain or potentially breaking
- **Dependencies**: any external libs, data, or config needed

## Stage 5: Handoff (for non-trivial tasks)

If the task involves 3+ files, new patterns, or risky changes:

```
Artifact: .opencode/memory/handoff-{YYYYMMDD}-{seq}.md
```

The handoff must follow the template defined in `docs/HANDOFF_TEMPLATE.md`.
Required sections:
- Task summary (from Stage 4 plan)
- Current codebase state (from Stage 1 scout)
- Key decisions made so far
- Files to touch and what to do in each (one subsection per file)
- Any pitfalls or gotchas discovered
- Verification criteria (how to confirm implementation is correct)

This file serves as the single source of truth for the implementer. Do NOT skip sections — incomplete handoffs cause implementation drift.

## Stage 6: Implement

Execute the plan. For each file:

1. Read the current file (if modifying).
2. Make the change following project conventions.
3. After each file, do a quick self-check: "does this match the plan?"

If you get stuck or discover something that invalidates the plan:
- Stop implementing.
- Update the handoff.md with the new finding.
- Return to Stage 4 (Plan) to revise.

## Stage 7: Checkpoint

Before declaring implementation done:

```
Artifact: .opencode/memory/checkpoint-{YYYYMMDD}-{seq}.md
```

### File-level check

- All planned files were touched?
- Any files were modified but not planned?
- The diff looks coherent?

### Syntax check

Run a quick syntax check for the project's language:

| Language | Command |
|----------|---------|
| Bash | `bash -n <file>` |
| Python | `python -m py_compile <file>` or `ruff check <file>` |
| TypeScript/JS | `npx tsc --noEmit --pretty` or `node -e "require('<file>')"` |
| Go | `go vet ./...` |
| Ruby | `ruby -c <file>` |

If syntax check fails: stop, note the exact error, and return to Stage 6.

### Quick test check

If the project has a test command (check `package.json`, `Cargo.toml`, `Makefile`, `pytest.ini`, etc.), run:

```
<test command> --quiet --dry-run    # if available
<test command> --list-tests         # fallback: just list to confirm test infra works
```

Do NOT run the full test suite — this is a quick check, not Stage 8.

### Artifact

Write the checkpoint result to `.opencode/memory/checkpoint-{YYYYMMDD}-{seq}.md`:

```yaml
---
stage: checkpoint
result: pass | fail
checks:
  file_check: pass | fail
  syntax_check: pass | fail (<error summary if fail>)
  quick_test: pass | fail | skipped
---
```

If all checks pass: note "checkpoint: passed" and proceed to Stage 8.
If any check fails: note what's wrong, include the error output, and return to Stage 6.

## Stage 8: Test & Review

1. Run the project's test/lint/typecheck commands if they exist.
2. If issues found, fix them directly (not a review step — fix and return to Stage 7).
3. If tests pass and code looks clean, load `omo-reviewer` subagent for a fresh perspective:
   `task({ subagent_type: "omo-reviewer", prompt: "<diff summary and goal>" })`
4. Read the reviewer's output from `.opencode/memory/review-*.md`.
5. If reviewer requests changes, address them and repeat Stage 7+8.

## Stage 9: Summary & Memory Update

```
Artifact: .opencode/memory/summary-{YYYYMMDD}-{seq}.md
```

Final artifact contains:
- What was done
- What was learned
- What state the project is in now
- Any open questions or follow-up tasks

Then load `omo-memory` skill and save this summary into memory.

## Workflow diagram (text)

```
User Request
    │
    ▼
[Stage 0] Intake ──trivial──► Direct handling
    │
    ▼ complex
[Stage 1] Local-scout ───────► scout-*.md
    │
    ▼
[Stage 2] Memory-reader ─────► (context loaded)
    │
    ▼
[Stage 3] Web-RAG? ──no──┐
    │ yes                  │
    ▼                      │
 web-rag skill/researcher  │
    │                      │
    ◄──────────────────────┘
    │
    ▼
[Stage 4] Plan ─────────────► plan-*.md
    │
    ▼
[Stage 5] Handoff ──────────► handoff-*.md (if non-trivial)
    │
    ▼
[Stage 6] Implement ────loop──┐
    │                          │
    ▼                          │ (if stuck)
[Stage 7] Checkpoint ─────────┤
    │                          │
    ▼ fail                     │
 review? ──fix──► goto Stage 6│
    │ pass                     │
    ▼                          │
[Stage 8] Test & Review ──────┘
    │                          │ (if changes requested)
    ▼                          │
[Stage 9] Summary & Memory ───┘
    │
    ▼
 Done → present result to user
```
