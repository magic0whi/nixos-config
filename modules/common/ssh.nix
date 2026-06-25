{
  config,
  lib,
  const,
  pkgs,
  ...
}:
{
  programs.ssh = lib.mkMerge [
    ## BEGIN Common
    {
      # Configs will be written to /etc/ssh/ssh_config
      extraConfig = lib.mkMerge [
        (lib.mkBefore ''
          Compression yes
          # Share multiple ssh session along one connection, this reduce the time cost on reconnection
          ControlMaster auto
          ControlPath ~/.ssh/master-%r@%n:%p
          # Increase the valid time of a connection
          ControlPersist 30m
          # Send keep-alive every 30s, disconnect if sent 5 times with no response
          ServerAliveInterval 30
          ServerAliveCountMax 5
        '')
        (lib.mkAfter (
          lib.concatMapAttrsStringSep "" (hostname: nics: ''
            Host ${hostname}
              Hostname ${
                let
                  fallback = "${hostname}.lan"; # NOTE: LLMNR don't work on remote machines
                in
                if config.services.easytier.enable then nics.easytier.ipv4NoCidr or fallback else nics.tailscale.ipv4NoCidr or fallback
              }
              Port 22
          '') config.vars.hostAddrs
        ))
      ];
      # Define the host key for remote builders so that Nix can verify all the remote builders.
      # This config will be written to /etc/ssh/ssh_known_hosts
      knownHosts = lib.mapAttrs (
        hostname: publicKey:
        let
          nics = config.vars.hostAddrs.${hostname} or { };
        in
        {
          # Hostname and its IPv4 & IPv6
          hostNames = [
            hostname
          ]
          ++ lib.optionals (nics ? easytier) (
            with nics.easytier;
            [
              ipv4NoCidr
              ipv6NoCidr
            ]
          )
          ++ lib.optionals (nics ? tailscale) (
            with nics.tailscale;
            [
              ipv4NoCidr
              ipv6NoCidr
            ]
          );
          inherit publicKey;
        }
      ) const.networking.knownHosts;
    }
    ## END Common
    ## BEGIN NixOS
    (lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
      startAgent = !config.home-manager.users.${const.username}.services.gpg-agent.enableSshSupport;
    })
    ## END NixOS
  ];
}
