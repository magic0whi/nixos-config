{ lib, ... }:
{
  # A forwarded agent socket lives only as long as its SSH connection, but zellij sessions outlive it and keep the stale
  # path.
  # Ref: https://github.com/zellij-org/zellij/issues/1637
  #
  programs.zsh.envExtra = ''
    # Point a stable symlink at the newest forwarded socket on each new SSH login
    if [ -n "$SSH_CONNECTION" ] && [ "$SSH_AUTH_SOCK" != "$HOME/.ssh/agent-forwarded.sock" ] && [ -S "$SSH_AUTH_SOCK" ]; then
      ln -sfn "$SSH_AUTH_SOCK" "$HOME/.ssh/agent-forwarded.sock"
      export SSH_AUTH_SOCK="$HOME/.ssh/agent-forwarded.sock"
    fi
  '';
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        # Default values
        # A private key that is used during authentication will be added to ssh-agent if it is running
        addKeysToAgent = "yes";
        # Allow to securely use local SSH agent to authenticate on the remote machine. It has the same effect as adding
        # CLI option `ssh -A user@host`
        forwardAgent = true;
      };
      "ssh.github.com hf.co" = lib.hm.dag.entryBefore [ "192.168.*" ] {
        user = "git";

        # Only use specific key
        # identityFile = "";
        # identitiesOnly = true; # Prevent sending default identity files first.
      };
      # "192.168.*" = {
      #   identityFile = "/etc/agenix/ssh-key-romantic"; # romantic holds my homelab~
      #   # Specifies that ssh should only use the identity file. Required to prevent sending default identity files
      #   identitiesOnly = true;
      # };
    };
  };
}
