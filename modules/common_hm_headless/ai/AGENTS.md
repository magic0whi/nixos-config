# Global preferences

<!--
  NOTE: This file is managed by nixos-config and shared with agentic coding
  tools (Claude Code, OpenCode, ...). Do NOT edit the deployed copies (e.g.
  ~/.claude/CLAUDE.md or ~/.config/opencode/AGENTS.md) directly — they are
  generated from the nix store and changes will be overwritten. Edit in
  nixos-config and rebuild instead.
-->

## Tooling

- **Always prefer pnpm.** Use `pnpm dlx` instead of `npx`, `pnpm add` instead of
  `npm install <pkg>`, `pnpm install` instead of `npm install`. Applies to every
  project unless that project explicitly requires a different package manager.

## Skills

- **Load the matching skill before doing the task.** If a request matches an
  available skill's description, load it first and follow its workflow instead
  of answering from memory or improvising an equivalent approach.
  - NixOS / Home Manager / nix-darwin option or nixpkgs package lookup → `nixos-search`
  - Nix builtin / `lib` function lookup → `noogle`
  - Commit message drafting or splitting commits → `git-commit`
- If you deliberately skip an applicable skill, say so and why.

## MCP servers

- **Anki tools need Anki running.** The `anki` MCP server is served by the
  `anki-mcp-server` add-on at `http://127.0.0.1:3141/`. If its tools are
  unavailable, ask the user to start Anki and reload the MCP connection.

## Dev environment (nix)

- **User uses nix.** If a needed tool/command is missing or the dev environment isn't
  ready (e.g. `command not found`), do NOT try to install it globally or work around it.
  Instead, remind the user to **exit the agent and run the appropriate nix dev shell**, e.g.
  `nix develop github:magic0whi/dev-flake#node` (swap `#node` for the relevant devshell),
  then restart the agent inside it.
- **direnv uses its own cache.** If a project's direnv env seems stale/broken, refresh the
  flake cache first, not just reload:
  `nix flake metadata --refresh github:magic0whi/dev-flake && direnv reload`.

## Git

- **Commit messages: propose, don't execute.** When the user asks for help writing git
  commit messages (or splitting changes into commits), only inspect the repo and propose
  messages plus a split plan. Never run `git commit` (`git cm`), `git push`, `git amend` (`git ame`), or any
  history-rewriting command unless the user explicitly asks to execute. Use the `git-commit`
  skill for the full workflow.
- **Conventional commits.** Default to `type(scope): subject` (feat, fix, chore, refactor,
  docs, test, ci, build). Imperative mood, ~50 char target, 72 max. Keep lockfile changes
  with the change that caused them. Include `Co-authored-by: <agent-name> <agent-email>` trailer when work is mostly done with AI.

## CLI tools (prefer these modern replacements)

The user's nixos-config installs these; default to them in commands/suggestions instead
of the classic tools (source: `Proteus/Projects/OSS/nixos-config`).

- grep → `rg` (ripgrep, built with PCRE2)
- find → `fd`
- cat → `bat`
- ls → `eza`
- cd → `zoxide` (`z`)
- sed → `sd` (simple), `sad` (interactive w/ diff preview), `ast-grep` (structural/code)
- cut/awk fields → `choose`
- diff → `difft` (difftastic); git diff aliases: `gitdf`/`gitdc`
- du → `dust` / `ncdu` / `gdu` • df → `duf`
- ps/top → `bottom` (`btm`)
- ping → `gping` • dig/nslookup → `doggo`
- time/benchmark → `hyperfine`
- make → `just` • tldr → `tealdeer` (`tldr`)
- git TUI → `lazygit` • file manager → `yazi` • multiplexer → `zellij`
- shell history → `atuin` • prompt → `starship` • editor → `helix`/`neovim`
- json → `jq` • yaml → `yq`
- nix builds → `nom` (nix-output-monitor); inspect: `nix-tree`, `nix-melt`
