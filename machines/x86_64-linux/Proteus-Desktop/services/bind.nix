{
  config,
  lib,
  const,
  pkgs,
  dns,
  ...
}:
{
  vars.hostAddrs = {
    Proteus-MBP14M4P = {
      tailscale = {
        ipv4 = "100.95.17.39/10";
        ipv6 = "fd7a:115c:a1e0::783a:1127/48";
      };
      easytier = {
        ipv4 = "10.0.0.4/24";
        ipv6 = "fdfe:dcba:9877::4/64";
      };
    };
    Proteus-NUC =
      let
        subs = [
          "immich"
          "jellyfin"
          "paperless"
          "sb-nuc"
          "sunshine"
          "syncthing-nuc"
          "traefik-nuc"
          # "sftpgo"
        ];
      in
      {
        tailscale = {
          ipv4 = "100.64.161.20/10";
          ipv6 = "fd7a:115c:a1e0::cd3a:a114/48";
          domains = {
            A = subs;
            AAAA = subs;
          };
        };
        easytier = {
          ipv4 = "10.0.0.2/24";
          ipv6 = "fdfe:dcba:9877::2/64";
          domains = {
            A = subs;
            AAAA = subs;
          };
        };
        wire.name = "enp46s0";
      };
    Proteus-Desktop =
      let
        domains =
          let
            sub = [
              "@"
              "ns1"
              "*.s3"
              "*.s3-pub"
              "algo-archive"
              "aria2"
              "atuin"
              "auth"
              "cockpit-desktop"
              "garage"
              "git"
              "hass"
              "ldap"
              "monero"
              "navidrome"
              "nextcloud"
              "niks3"
              "nixos-search"
              "noogle"
              "notebook"
              "opensearch-dashboards"
              "papra"
              "plane"
              "postgresql"
              "ql"
              "s3"
              "s3-pub"
              "sb-desktop"
              "syncthing-desktop"
              "traefik-desktop"
            ];
          in
          {
            A = sub;
            AAAA = sub;
          };
      in
      {
        tailscale = {
          ipv4 = "100.89.227.22/10";
          ipv6 = "fd7a:115c:a1e0::1a01:e318/48";
          inherit domains;
        };
        easytier = {
          ipv4 = "10.0.0.3/24";
          ipv6 = "fdfe:dcba:9877::3/64";
          inherit domains;
        };
        wire.name = "enp4s0";
        wireless = {
          name = "wlp0s20u9";
          ipv4 = "192.168.12.1/24";
        };
      };
  };

  debug = dns.lib.toString const.domain {
    useOrigin = true;
    SOA = {
      # Human readable names for fields
      nameServer = "ns1.${const.domain}.";
      adminEmail = const.email; # Email address with a real `@`!
      serial = const.networking.soaSerial;
      # Sane defaults for the remaining ones
    };

    NS = [ "ns1.${const.domain}." ];

    A = (
      with config.vars.hostAddrs.Proteus-Desktop;
      [
        easytier.ipv4NoCidr
        tailscale.ipv4NoCidr
      ]
    );

    AAAA = with config.vars.hostAddrs.Proteus-Desktop; [
      easytier.ipv6NoCidr
      tailscale.ipv6NoCidr
    ];

    subdomains = lib.mkMerge (
      lib.flatten (
        # Hosts
        lib.mapAttrsToList (
          _: host:
          # Hosts' NICs
          lib.mapAttrsToList (
            _: nic:
            # NIC's subdomains
            lib.mapAttrsToList (
              type: subs:
              builtins.foldl' (
                acc: sub:
                acc
                // {
                  ${sub}.${type} = lib.singleton (
                    if type == "A" then
                      nic.ipv4NoCidr
                    else if type == "AAAA" then
                      nic.ipv6NoCidr
                    else
                      null
                  );
                }
              ) { } subs
            ) nic.domains
          ) host
        ) config.vars.hostAddrs
      )
    );
  };
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
    cacheNetworks = [ "none" ]; # Do not allow access to cache
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
    ++ (builtins.catAttrs "ipv4" const.networking.hostAddrs.${config.networking.hostName});
    listenOnIpv6 = [
      "::1"
    ]
    ++ (builtins.catAttrs "ipv6" const.networking.hostAddrs.${config.networking.hostName});
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

      # Who can request zone transfers (full zone dump)
      allow-transfer { none; };
      # Who can dynamic DNS updates (add/remove records on the fly).
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
      ${const.domain} = {
        bindZoneOptions = {
          master = true;
          # Apply the DNSSEC policy to sign the zone locally
          extraConfig = "dnssec-policy custom;";
        };
        mutable = true;
        soa = {
          rName = const.email;
          serial = toString const.networking.soaSerial;
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
          ) (lib.filterAttrs (name: _: builtins.elem name allowed_hosts) const.networking.hostAddrs);
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
            "Host(`${const.domain}`)"
            " || Host(`ns1.${const.domain}`)"
            " || Host(`${config.networking.hostName}.${const.tailnet}`)"
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
            "HostSNI(`${const.domain}`)"
            "|| HostSNI(`ns1.${const.domain}`)"
            "|| HostSNI(`proteus-nuc.${const.tailnet}`)"
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
}
