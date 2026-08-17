# Global preferences

<!--
  NOTE: This file is managed by nixos-config (home-manager `programs.claude-code.context`).
  Do NOT edit ~/.claude/CLAUDE.md directly — it is a read-only symlink into the nix store
  and changes will be overwritten. Edit
  `modules/common_hm_headless/claude-code/CLAUDE.md` in nixos-config and rebuild instead.
-->

## Tooling

- **Always prefer pnpm.** Use `pnpm dlx` instead of `npx`, `pnpm add` instead of
  `npm install <pkg>`, `pnpm install` instead of `npm install`. Applies to every
  project unless that project explicitly requires a different package manager.

## Dev environment (nix)

- **User uses nix.** If a needed tool/command is missing or the dev environment isn't
  ready (e.g. `command not found`), do NOT try to install it globally or work around it.
  Instead, remind the user to **exit Claude and run the appropriate nix dev shell**, e.g.
  `nix develop github:magic0whi/dev-flake#node` (swap `#node` for the relevant devshell),
  then restart Claude inside it.
- **direnv uses its own cache.** If a project's direnv env seems stale/broken, refresh the
  flake cache first, not just reload:
  `nix flake metadata --refresh github:magic0whi/dev-flake && direnv reload`.

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
