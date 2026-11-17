---
name: git-commit
description:
  Helps write git commit messages and propose how to split staged/unstaged changes into
  focused commits. Use when the user asks to "write git messages", "commit message",
  "split commits", or wants help drafting commit text. Only proposes messages and a plan;
  never runs git commit/push unless the user explicitly asks to execute.
---

# Git Commit Message Helper

## Core rule

This skill **never** executes `git commit` (`git cm`), `git push`, `git amend` (`git ame`), or any
history-rewriting command on its own. It only inspects the repository and proposes commit messages
plus a split plan.

## Workflow

### 1. Inspect (read-only)

Run these to understand state and conventions:

- `git st --short`
- `gitdc` (staged) and `gitdf` (unstaged) — summarize, don't dump huge diffs
- `git log --no-merges -n 15 --oneline` (and `-- <touched paths>` if a single area) to learn the
  repo's prefix/scope convention, emoji usage, and capitalization
- Check for `.gitmessage`, `CONTRIBUTING.md`, PR templates, or commitlint config if present

### 2. Group changes into logical commits

- One concern per commit; prefer atomic commits over one big commit.
- Group by scope/area (e.g. `flake`, `python`, `rust`, `latex`), not by file count.
- Keep lockfile changes with the input/config change that caused them.
- Don't mix refactors with feature/fix changes unless trivially coupled.

### 3. Draft messages

Follow the repo's convention (default: Conventional Commits).

- Subject: imperative mood, lowercase after prefix, aim ~50 chars, hard ceiling 72.
  - Format: `type(scope): short description`
  - Common types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `ci`, `build`.
- Body: include ONLY when the diff doesn't show the effect (data migration, format change,
  running system touched, option semantics changed). At most 2 sentences / 40 words, each naming
  an effect, not a motive. Never list files, counts, or how the problem was found.
- Trailers: place at the bottom of the commit message separated by a blank line.
  - Add `Co-authored-by: <agent-name> (<model-name>) <agent-email>` when the work/changes were
    mostly done with AI, naming the model that produced the changes
    (e.g. `Co-authored-by: OpenCode (DeepSeek V4.1 Flash 1017) <noreply@opencode.ai>`).
  - Use the exact model name reported by the harness; if several models contributed, list them
    in the parenthetical (e.g. `(<model-a>, <model-b>)`).
  - Other trailers (`Fixes:`, `Refs:`, `BREAKING CHANGE:`) only if the repo uses them.

### 4. Present the plan

Show each commit as a heading, the complete message in a `text` fence, and one
staging command:

````markdown
## Commit 1

```text
type(scope): subject

Optional body paragraph.

Co-authored-by: <agent-name> (<model-name>) <agent-email>
```

```bash
git add path/a path/b
```
````

Rules:

- Put the body inside the message fence, separated from the subject by one blank
  line. Never print a standalone `Body:` line.
- Omit the body entirely when there is none — do not print "No body." or a
  placeholder.
- When only part of a file belongs to the commit, use one interactive `git add -p <paths>` and name the hunks to pick.
- Add a short note after the command when the hunk selection is non-obvious.

### 5. Edge cases

- Huge diffs: summarize by file/hunk; offer to drill into specific files.

## What NOT to do

- Don't commit, push, amend, rebase, reset, or stash without explicit instruction.
- Don't write bodies that restate the diff.
- Don't guess package versions, issue numbers, or ticket IDs.
