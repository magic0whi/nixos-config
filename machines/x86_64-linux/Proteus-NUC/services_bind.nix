{
  config,
  lib,
  myvars,
  pkgs,
  ...
}:
{
  networking.firewall = {
    allowedTCPPorts = [
      53
      853
    ];
    allowedUDPPorts = [ 53 ]; # Bind don't support DNS-over QUIC
  };
  services.bind = {
    enable = true;
    # Persistent directory for DNSSEC key states. Defaults to "/run/named", which clears on reboot.
    # directory = "/srv/bind";

    # Access-control of what networks are allowed for recursive queries
    # cacheNetworks = [
    #   "127.0.0.0/8" "::1/128"
    #   "100.64.0.0/10" "fd7a:115c:a1e0::/48"
    #   "192.168.0.0/16"
    # ];
    forwarders = [ ];
    # Bind standard port 53 strictly to the specific interface IPs
    listenOn = [
      "127.0.0.1"
    ]
    ++ (lib.concatMap (
      iface: lib.optional (iface ? ipv4) iface.ipv4
    ) myvars.networking.hosts_addr.${config.networking.hostName});
    listenOnIpv6 = [
      "::1"
    ]
    ++ (lib.concatMap (
      iface: lib.optional (iface ? ipv6) iface.ipv6
    ) myvars.networking.hosts_addr.${config.networking.hostName});
    # Inject the variables into the raw extraOptions string for DoT and DoH
    extraOptions = ''
      # Strictly Authoritative-Only Mode, implies 'empty-zones-enable no'
      recursion no;

      # Dedicated unencrypted TCP port strictly for Traefik's DoT proxy stream
      listen-on port 8530 proxy plain { 127.0.0.1; };
      listen-on-v6 port 8530 proxy plain { ::1; };

      # Plain HTTP endpoint strictly for Traefik's DoH forwarding
      listen-on port 8053 tls none http default { 127.0.0.1; };
      listen-on-v6 port 8053 tls none http default { ::1; };

      # Trust PROXYv2 headers from Traefik
      # Who is talking to me?
      allow-proxy { 127.0.0.1; ::1; };
      # Which of my doors are they knocking on?
      allow-proxy-on { 127.0.0.1; ::1; };

      allow-transfer { none; };
      allow-update { none; };
      server-id none;

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
    domains = {
      ${myvars.domain} = {
        bindZoneOptions = {
          master = true;
          # Apply the DNSSEC policy to sign the zone locally
          extraConfig = "dnssec-policy custom;";
        };
        mutable = true;
        soa = {
          rName = myvars.useremail;
          serial = "2026052301";
        };
        networks = [
          {
            v4PrefixLen = 10 / 8;
            v6PrefixLen = 48 / 4;
          }
          {
            v4PrefixLen = 24 / 8;
            v6PrefixLen = 64 / 4;
          }
        ];
        hosts =
          let
            allowed_hosts = [
              "Proteus-NUC"
              "Proteus-MBP14M4P"
              "Proteus-Desktop"
            ]
            ++ map (i: "Proteus-NixOS-${toString i}") (lib.range 0 5);
          in
          lib.mapAttrs (
            _: ifaces:
            map (
              iface:
              lib.filterAttrs (
                key: _:
                builtins.elem key [
                  "ipv4"
                  "ipv6"
                  "domains"
                ]
              ) iface
            ) ifaces
          ) (lib.filterAttrs (name: _: builtins.elem name allowed_hosts) myvars.networking.hosts_addr);
      };
    };
  };

  services.traefik = {
    staticConfigOptions.entryPoints.dot.address = ":853"; # Add the standard DoT port as a TCP entrypoint
    dynamicConfigOptions = {
      http = {
        routers.doh = {
          # Intercept standard DoH queries at the apex domain
          rule = lib.concatStrings [
            "("
            "Host(`${myvars.domain}`)"
            " || Host(`ns1.${myvars.domain}`)"
            " || Host(`${config.networking.hostName}.${myvars.tailnet}`)"
            ")"
            " && Path(`/dns-query`)"
          ];
          entryPoints = [ "websecure" ];
          tls = { };
          service = "doh";
        };
        # Use HTTP/2 Cleartext (h2c) when talking to BIND's local port.
        services.doh.loadBalancer.servers = [
          { url = "h2c://127.0.0.1:8053"; }
          { url = "h2c://[::1]:8053"; }
        ];
      };
      tcp = {
        routers.dot = {
          rule = builtins.concatStringsSep " " [
            "HostSNI(`${myvars.domain}`)"
            "|| HostSNI(`ns1.${myvars.domain}`)"
            "|| HostSNI(`proteus-nuc.${myvars.tailnet}`)"
          ];
          entryPoints = [ "dot" ];
          service = "dot";
          tls = { };
        };
        # Forward raw DNS to BIND's local 53
        services.dot.loadBalancer = {
          proxyProtocol.version = 2;
          servers = [
            { address = "127.0.0.1:8530"; }
            { address = "[::1]:8530"; }
          ];
        };
      };
    };
  };

  services.resolved.settings.Resolve = {
    # This triggers recursive queries to the apex domain, which slows down domestic sites. It can also completely break
    # your internet access if the proxy server goes down while systemd-resolved is fetching DS records for proxied apex
    # domains like "com"
    DNSSEC = "allow-downgrade";
    Domains = [
      "~${myvars.domain}" # The '~' prefix makes this a routing domain
    ]
    ++ (lib.mapAttrsToList (
      _: zone:
      if (lib.isDerivation zone.file) then
        "~${lib.removeSuffix ".zone" zone.file.name}"
      else
        "~${lib.removeSuffix ".zone" zone.file}"
    ) config.services.bind.zones);

    DNS =
      (lib.concatMap (
        iface: lib.optional (iface ? ipv4) "${iface.ipv4}#${myvars.domain}"
      ) myvars.networking.hosts_addr.${config.networking.hostName})
      ++ (lib.concatMap (
        iface: lib.optional (iface ? ipv6) "${iface.ipv6}#${myvars.domain}"
      ) myvars.networking.hosts_addr.${config.networking.hostName});
  };

  # Trust Island
  # NOTE: To get a DS records for reverse zone, query the zone apex (`proteus.eu.org`, `161.64.100.in-addr.arpa`
  # `0.e.1.a.c.5.1.1.a.7.d.f.ip6.arpa`)
  # nix run nixpkgs#dig -- @100.64.161.20 161.64.100.in-addr.arpa DNSKEY +noall +answer | nix shell nixpkgs#bind --command dnssec-dsfromkey -f - 161.64.100.in-addr.arpa
  # Or
  # nix run nixpkgs#dig -- @100.64.161.20 161.64.100.in-addr.arpa DNSKEY +noall +answer | nix shell nixpkgs#ldns.examples --command ldns-key2ds -n /dev/stdin
  sops =
    let
      sopsFile = "${myvars.secrets_dir}/${config.networking.hostName}.sops.yaml";
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
    # Generate the install commands for all pub keys (main + reverse)
    lib.concatMapStringsSep "\n" (
      file: "install -m 0644 ${file} ${config.services.bind.directory}/${file.name}"
    ) zones_pubs;

  environment.etc."dnssec-trust-anchors.d/${myvars.domain}.positive".text = ''
    ${myvars.domain}. IN DS 40751 15 2 EFFF70FD3922613584774DE050E31D5A3FFF988E45EB5C75296BF448B5B01FCF
  '';
  environment.etc."dnssec-trust-anchors.d/ts_v4_rev_zone.positive".text = ''
    100.in-addr.arpa. IN DS 16452 15 2 673360156B641DBA72909952F230FA34A6FA8D8D249A8A8A55C05A94EC6794FF
  '';
  environment.etc."dnssec-trust-anchors.d/ts_v6_rev_zone.positive.positive".text = ''
    0.e.1.a.c.5.1.1.a.7.d.f.ip6.arpa. IN DS 2790 15 2 B90A8FDD8D504FC3182F57750FC433EF8D43AFA8ABE6716A3DC49BFBCCD5F3EA
  '';
  environment.etc."dnssec-trust-anchors.d/et_v4_rev_zone.positive".text = ''
    0.0.10.in-addr.arpa. IN DS 3009 15 2 E93B662038A9985D4A4BAEA2F619593EF4699EAFA08612BD7C3FCD00691FA85C
  '';
  environment.etc."dnssec-trust-anchors.d/et_v6_rev_zone.positive.positive".text = ''
    0.0.0.0.7.7.8.9.a.b.c.d.e.f.d.f.ip6.arpa. IN DS 1147 15 2 2DCEF637F1D130E0CF63F33FEF81C99E01C8B187A8AE75A3985545400FF4A763
  '';
}
