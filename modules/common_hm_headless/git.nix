{
  config,
  lib,
  myvars,
  pkgs,
  ...
}:
{
  # programs.gh.enable = true; # GitHub CLI tool

  # `programs.git` will generate the config file: `~/.config/git/config` to make Git use this config file,
  # `~/.gitconfig` should not exist!
  home.activation.remove_existing_git_config = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    rm -f ${config.home.homeDirectory}/.gitconfig
  '';
  home.packages = with pkgs; [
    # Automatically trims your branches whose tracking remote refs are merged or gone. It's really useful when you
    # working on a project for a long time.
    git-trim
    gitleaks
  ];
  programs.git = {
    enable = true;
    package = pkgs.emptyDirectory; # Already in `environment.systemPackages`, set to dummy package
    lfs.enable = true; # Used by huggingface models
    settings = {
      user.name = myvars.userFullName;
      user.email = myvars.email;
      init.defaultBranch = "main";
      trim.bases = "develop,master,main"; # For git-trim
      push.autoSetupRemote = true;
      pull.rebase = true;
      core.hooksPath = ".git_hooks";
      difftool.difftastic.cmd = "${lib.getExe config.programs.difftastic.package} $LOCAL $REMOTE";
      url = {
        # New machines that lacks of a SSH Agent / key may not able to clone repo anonymously
        # Replace https with ssh
        # "ssh://git@ssh.github.com:443/${myvars.githubUsername}" = {
        #   insteadOf = "https://github.com/${myvars.githubUsername}";
        # };
        # "ssh://git@gitlab.com/" = {
        #   insteadOf = "https://gitlab.com/";
        # };
        # "ssh://git@bitbucket.com/" = {
        #   insteadOf = "https://bitbucket.com/";
        # };
      };
      alias =
        let
          log_fmt = "--pretty=${lib.escapeShellArg "format:%C(green)%G? %C(yellow)%h%C(auto)%d %s %C(blue)[%cn]%C(reset)"}";
        in
        {
          # Custom aliases for git
          br = "branch";
          co = "checkout";
          st = "status";
          # Format placeholders:
          # - %C(...): color specification, respecting the auto settings
          # - %G?: Show signature status
          # - %cn: committer name
          # - %d: ref name. e.g. ' (HEAD)' (yes it has a prefix space)
          # - %h: abbreviated commit hash. e.g. 'c4f4c1f'
          # - %s: subject. e.g. 'feat: consolidate configs and enhance shell in NixOS/Darwin'
          ls = "log --graph ${log_fmt}";
          ll = "log --graph --numstat ${log_fmt}";
          la = "log --graph --all ${log_fmt}";
          cm = "commit -sm"; # Commit via `git cm <message>`
          ca = "commit -asm"; # Commit all changes via `git ca <message>`
          dc = "diff --cached";
          amend = "commit --amend -m"; # Amend commit message via `git amend <message>`
          unstage = "reset HEAD --"; # Unstage file via `git unstage <file>`
          merged = "branch --merged"; # List merged(into HEAD) branches via `git merged`
          unmerged = "branch --no-merged"; # List unmerged(into HEAD) branches via `git unmerged`
          nonexist = "remote prune origin --dry-run"; # List non-exist(remote) branches via `git nonexist`

          # Delete merged branches except master & dev & staging. `!` indicates it's a shell script, not a git subcommand
          delmerged = ''! git branch --merged | egrep -v "(^\*|main|master|dev|staging)" | xargs git branch -d'';
          delnonexist = "remote prune origin"; # Delete non-exist (remote) branches

          # Aliases for submodule
          update = "submodule update --init --recursive";
          foreach = "submodule foreach";
        };
    };
    # includes = [
    #   # e.g., Use different Email & Name for work
    #   {
    #     condition = "gitdir:~/work/";
    #     path = "~/work/.gitconfig";
    #   }
    # ];
    signing = {
      format = "openpgp";
      key = myvars.git_signingkey;
      signByDefault = true;
    };
  };
  # A syntax-highlighting pager written in Rust
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      diff-so-fancy = true;
      line-numbers = true;
      true-color = "always";
      # features = ""; # features are named groups of settings, used to keep related settings organized
    };
  };
  programs.difftastic = {
    enable = true;
    git = {
      enable = !config.programs.delta.enableGitIntegration;
      # Persists as of 2026-05-23, https://github.com/nix-community/home-manager/issues/8592
      # diffToolMode = true;
    };
  };
}
