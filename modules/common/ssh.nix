{
  config,
  lib,
  myvars,
  pkgs,
  ...
}:
{
  programs.ssh = {
    # Configs will be written to /etc/ssh/ssh_config
    extraConfig = lib.mkMerge [
      (lib.mkBefore ''
        Compression yes
        ControlMaster auto
        ControlPath ~/.ssh/master-%r@%n:%p
        ControlPersist 30m
        ServerAliveInterval 30
        ServerAliveCountMax 5
      '')
      (lib.mkAfter (
        lib.foldlAttrs (
          acc: hostname: ifaces:
          acc
          + ''
            Host ${hostname}
              Hostname ${
                let
                  ts_iface = builtins.elemAt ifaces 0;
                  et_iface = lib.optionalAttrs (builtins.length ifaces >= 2) (builtins.elemAt ifaces 1);
                in
                if et_iface ? ipv4 then
                  et_iface.ipv4
                else if ts_iface ? ipv4 then
                  ts_iface.ipv4
                else
                  hostname
              }
              Port 22
          ''
        ) "" myvars.networking.hosts_addr
      ))
    ];
    # Define the host key for remote builders so that Nix can verify all the remote builders.
    # This config will be written to /etc/ssh/ssh_known_hosts
    knownHosts = lib.mapAttrs (
      name: val:
      let
        ifaces = myvars.networking.hosts_addr.${name} or [ ];
        ts_iface = lib.optionalAttrs (ifaces != [ ]) (builtins.elemAt ifaces 0);
        et_iface = lib.optionalAttrs (builtins.length ifaces >= 2) (builtins.elemAt ifaces 1);
      in
      {
        hostNames = [
          name
        ] # Hostname and its IPv4 & IPv6
        ++ ((lib.optional (ts_iface ? ipv4) ts_iface.ipv4) ++ (lib.optional (ts_iface ? ipv6) ts_iface.ipv6))
        ++ ((lib.optional (et_iface ? ipv4) et_iface.ipv4) ++ (lib.optional (et_iface ? ipv6) et_iface.ipv6));
        publicKey = val.public_key;
      }
    ) myvars.networking.known_hosts;
  }
  // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
    # TODO: May be unnecessary
    # extraConfig = lib.optionalString config.home-manager.users.${myvars.username}.services.gpg-agent.enableSshSupport ''
    #   Host *
    #     IdentityAgent /run/user/${toString config.users.users.${myvars.username}.uid}/gnupg/S.gpg-agent.ssh
    # '';
    # TIP: Use `ssh-add` to add a key to the agent.
    startAgent = !config.home-manager.users.${myvars.username}.services.gpg-agent.enableSshSupport;
  };
}
