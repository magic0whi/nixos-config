{
  const,
  config,
  lib,
  pkgs,
  ...
}:
{
  # Persistent directory for DNSSEC key states. Defaults to "/run/named", which clears on reboot.
  # Optional if pinned key and the keys has unlimited lifetime
  # directory = "/srv/bind";
  services.bind = {
    extraOptions = ''
      # Disable global validation if relying solely on the trusted island
      dnssec-validation no;
    '';
    extraConfig = ''
      # DNSSEC Trusted Island Policy
      dnssec-policy custom {
        keys {
          csk key-directory lifetime unlimited algorithm 15; # ED25519
        };
        max-zone-ttl 24h;
        signatures-refresh 8d; # Regenerate 8 days before expire
        signatures-validity 10d; # ZSK validity last for 10 days
        signatures-validity-dnskey 10d; # KSK validity last for 10 days
      };
    '';
  };

  ## BEGIN DNSSEC
  # NOTE: To get a DS records for reverse zone, query the zone apex (`proteus.eu.org`, `161.64.100.in-addr.arpa`
  # `0.e.1.a.c.5.1.1.a.7.d.f.ip6.arpa`)
  # nix run nixpkgs#dig -- @100.64.161.20 161.64.100.in-addr.arpa DNSKEY +noall +answer | nix shell nixpkgs#bind --command dnssec-dsfromkey -f - 161.64.100.in-addr.arpa
  # Or
  # nix run nixpkgs#dig -- @100.64.161.20 161.64.100.in-addr.arpa DNSKEY +noall +answer | nix shell nixpkgs#ldns.examples --command ldns-key2ds -n /dev/stdin
  sops =
    let
      sopsFile = "${const.secretsDir}/${config.networking.hostName}.sops.yaml";
      restartUnits = [ "bind.service" ];
      owner = config.systemd.services.bind.serviceConfig.User;
      mode = "0600";
    in
    {
      secrets = {
        "bind_domain_zone_priv" = { inherit sopsFile restartUnits; };
        "bind_ts_v4_rev_zone_priv" = { inherit sopsFile restartUnits; };
        "bind_ts_v6_rev_zone_priv" = { inherit sopsFile restartUnits; };
        "bind_et_v4_rev_zone_priv" = { inherit sopsFile restartUnits; };
        "bind_et_v6_rev_zone_priv" = { inherit sopsFile restartUnits; };
      };
      templates =
        let
          shared_priv_cfg = ''
            Private-key-format: v1.3
            Algorithm: 15 (ED25519)
          '';
          shared_priv_timestamp = ''
            Created: 20260523080310
            Publish: 20260523080310
            Activate: 20260523080310
            SyncPublish: 20260524080810
          '';
        in
        {
          "bind_domain_zone_priv" = {
            inherit restartUnits owner mode;
            content = shared_priv_cfg + "PrivateKey: ${config.sops.placeholder.bind_domain_zone_priv}\n" + shared_priv_timestamp;
            path = "${config.services.bind.directory}/Kproteus.eu.org.+015+40751.private";
          };
          "bind_ts_v4_rev_zone_priv" = {
            inherit restartUnits owner mode;
            content = shared_priv_cfg + "PrivateKey: ${config.sops.placeholder.bind_ts_v4_rev_zone_priv}\n" + shared_priv_timestamp;
            path = "${config.services.bind.directory}/K100.in-addr.arpa.+015+16452.private";
          };
          "bind_ts_v6_rev_zone_priv" = {
            inherit restartUnits owner mode;
            content = shared_priv_cfg + "PrivateKey: ${config.sops.placeholder.bind_ts_v6_rev_zone_priv}\n" + shared_priv_timestamp;
            path = "${config.services.bind.directory}/K0.e.1.a.c.5.1.1.a.7.d.f.ip6.arpa.+015+02790.private";
          };
          "bind_et_v4_rev_zone_priv" = {
            inherit restartUnits owner mode;
            content = shared_priv_cfg + "PrivateKey: ${config.sops.placeholder.bind_et_v4_rev_zone_priv}\n" + shared_priv_timestamp;
            path = "${config.services.bind.directory}/K0.0.10.in-addr.arpa.+015+03009.private";
          };
          "bind_et_v6_rev_zone_priv" = {
            inherit restartUnits owner mode;
            content = shared_priv_cfg + "PrivateKey: ${config.sops.placeholder.bind_et_v6_rev_zone_priv}\n" + shared_priv_timestamp;
            path = "${config.services.bind.directory}/K0.0.0.0.7.7.8.9.a.b.c.d.e.f.d.f.ip6.arpa.+015+01147.private";
          };
        };
    };

  systemd.services.bind.preStart =
    let
      zones_pubs = [
        (pkgs.writeText "Kproteus.eu.org.+015+40751.key" ''
          proteus.eu.org. 3600 IN DNSKEY 257 3 15 f1EhcwJnyqstgxFUySK5m650d2fg+w8DLh8FNwVKHTc=
        '')
        (pkgs.writeText "K100.in-addr.arpa.+015+16452.key" ''
          100.in-addr.arpa. 3600 IN DNSKEY 257 3 15 PwFirzXup9sShggRjrky0w1g+OgDc32HLIJ9n+acyJM=
        '')
        (pkgs.writeText "K0.e.1.a.c.5.1.1.a.7.d.f.ip6.arpa.+015+02790.key" ''
          0.e.1.a.c.5.1.1.a.7.d.f.ip6.arpa. 3600 IN DNSKEY 257 3 15 VZFDZ7Hu0xm2Lu/8myOO5zpAs9fjNTx6nfeNq6Y4OPo=
        '')
        (pkgs.writeText "K0.0.10.in-addr.arpa.+015+03009.key" ''
          0.0.10.in-addr.arpa. 3600 IN DNSKEY 257 3 15 r3yhoiw0ch3YhWpvVNneJ9hTuxwfrc9rl+dJVbm+hMQ=
        '')
        (pkgs.writeText "K0.0.0.0.7.7.8.9.a.b.c.d.e.f.d.f.ip6.arpa.+015+01147.key" ''
          0.0.0.0.7.7.8.9.a.b.c.d.e.f.d.f.ip6.arpa. 3600 IN DNSKEY 257 3 15 wP+4ropyVJWnhxzY67Lx1WDlW2b2yZ7M/fpzMZVurU4=
        '')
      ];
    in
    # Generate the install commands for all public keys
    lib.concatMapStringsSep "\n" (
      file: "install -m 0644 ${file} ${config.services.bind.directory}/${file.name}"
    ) zones_pubs;
  ## END DNSSEC
}
