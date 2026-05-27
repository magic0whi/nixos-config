{ lib, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
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
        # identityFile = "";
        identitiesOnly = true; # Prevent sending default identity files first.
      };
      # "192.168.*" = {
      #   identityFile = "/etc/agenix/ssh-key-romantic"; # romantic holds my homelab~
      #   # Specifies that ssh should only use the identity file. Required to prevent sending default identity files
      #   # first.
      #   identitiesOnly = true;
      # };
    };
  };
}
