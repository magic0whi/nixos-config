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
plus a split plan. Execution happens only when the user explicitly says to commit/push (e.g. "go ahead",
"commit it", "do it"). If unsure, ask.

## Workflow

### 1. Inspect (read-only)

Run these (in parallel) to understand state and conventions:

- `git st --short`
- `gitdc` (staged) and `gitdf` (unstaged) — summarize, don't dump huge diffs
- `git log --no-merges -n 15 --oneline` (and `-- <touched paths>` if a single area) to learn the
  repo's prefix/scope convention, emoji usage, and capitalization
- Check for `.gitmessage`, `CONTRIBUTING.md`, PR templates, or commitlint config if present

Name the convention you found (e.g. Conventional Commits with scope, emoji prefix) before drafting.

### 2. Group changes into logical commits

- One concern per commit; prefer atomic commits over one big commit.
- Group by scope/area (e.g. `flake`, `python`, `rust`, `latex`), not by file count.
- Keep lockfile changes with the input/config change that caused them.
- Don't mix refactors with feature/fix changes unless trivially coupled.
- Unstaged changes are reported separately; only include them if the user asks.

### 3. Draft messages

Follow the repo's convention (default: Conventional Commits).

- Subject: imperative mood, lowercase after prefix, aim ~50 chars, hard ceiling 72.
  - Format: `type(scope): short description`
  - Common types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `ci`, `build`.
- Body: include ONLY when the diff doesn't show the effect (data migration, format change,
  running system touched, option semantics changed). At most 2 sentences / 40 words, each naming
  an effect, not a motive. Never list files, counts, or how the problem was found.
- Trailers: place at the bottom of the commit message separated by a blank line.
  - Add `Co-authored-by: <agent-name> <agent-email>` when the work/changes were mostly done with AI
    (e.g. `Co-authored-by: OpenCode <noreply@opencode.ai>` or your agent's equivalent).
  - Other trailers (`Fixes:`, `Refs:`, `BREAKING CHANGE:`) only if the repo uses them.
- Don't invent reasons; if a motivation is unclear, ask the user.

### 4. Present the plan

Show a compact plan before any action:

```
Commit 1: <subject>
  Files: a, b
  Body: (none | one line)

Commit 2: ...
```

Then ask: "Apply these messages? (yes / adjust / split differently / cancel)"

### 5. Execute only on explicit approval

If the user approves and asks to commit:

- Stage files per group (`git add <paths>`), then `git cm "..."` (or `-F` for multi-paragraph).
- Respect the repo's pre-commit hooks; on failure, fix the cause and recommit — never `git ame`
  a commit that may already be pushed, and never `--no-verify`.
- Push only if explicitly requested; never force-push without explicit confirmation.

### 6. Edge cases

- Nothing staged: propose a staging plan grouped by concern, don't stage without asking.
- Mixed staged/unstaged: clearly separate; warn that unstaged changes won't be committed.
- Detached HEAD / rebase in progress: warn and stop.
- Huge diffs: summarize by file/hunk; offer to drill into specific files.

## What NOT to do

- Don't commit, push, amend, rebase, reset, or stash without explicit instruction.
- Don't write bodies that restate the diff.
- Don't omit AI co-author trailers (`Co-authored-by: <agent-name> <agent-email>`) when the work was mostly done with AI.
- Don't guess package versions, issue numbers, or ticket IDs.
