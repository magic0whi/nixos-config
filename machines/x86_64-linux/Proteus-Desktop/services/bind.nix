{
  config,
  lib,
  const,
  dns,
  pkgs,
  ...
}:
let
  inherit (dns.util.${pkgs.stdenv.system}) writeZone;
  shared_head_cfg = {
    useOrigin = true;
    SOA = {
      nameServer = "ns1.${const.domain}.";
      adminEmail = const.email;
      serial = const.networking.soaSerial;
      # Sane defaults for the remaining ones
    };
    NS = [ "ns1.${const.domain}." ];
  };

  # Rewrite of the old gen_subdomain_records in https://github.com/NixOS/nixpkgs/pull/522745
  # It's lure to use `builtins.zipAttrsWith` here, the problem is the loop sequence, you'll found you must loop
  # subdomains for the attribute names, as the dns.nix requires the format:
  # <subname>.A = [ IP1 IP2 ... ]
  # But if you loop subdomains first this means all the NICs in a host shares the same subdomain list
  mkSubdomainRecords =
    hostAddrs:
    let
      # Convert subnames to records
      # A "11.4.5.14" [ subname1  subname 2 ... ]
      # -> { subname1.A = [ "11.4.5.14" ];  subname2.A = [ "11.4.5.14" ]; ... }
      concat_map_subs = type: target: builtins.foldl' (acc: sub: acc // { ${sub}.${type} = lib.singleton target; }) { };

      # Traverse NIC's subdomains (may have types A, AAAA)
      # { A = [ subname1 ... ]; AAAA = [ subname1 ... ]; }
      #  -> [
      #   { subname1.A = nic.ipv4NoCidr; }
      #   { subname1.AAAA = nic.ipv6NoCidr; }
      # ]
      # I can do recursive merge but it's senseless at this stage as other NICs may contain same subname, as well as
      # other hosts, so just make all the records molecule and finally do `lib.mkMerge` at the option level.
      concat_map_sub_types =
        nic:
        lib.mapAttrsToList (type: concat_map_subs type (if type == "A" then nic.ipv4NoCidr else nic.ipv6NoCidr)) nic.subdomains;

      # Traverse hosts' NICs
      concat_map_nics = host: lib.concatMap concat_map_sub_types (builtins.attrValues host);
    in
    # Traverse hosts
    lib.concatMap concat_map_nics (builtins.attrValues hostAddrs);

  # [ "@" subname1 ] -> [ example.com. subname1.example.com. ]
  gen_ptr_targets =
    subs:
    map (sub: if sub == "@" then "${const.domain}." else "${sub}.${const.domain}.")
      # Reverse records doesn't support wildcard subnames
      (lib.filter (sub: !lib.hasInfix "*" sub) subs);

  # Rewrite of the old gen_reverse_v4_records in https://github.com/NixOS/nixpkgs/pull/522745
  mkIPv4ReverseRecords =
    depth: nicName:
    let
      # { A = [ subname1 ...]; AAAA = [ subname2 ...]; } -> [ subname1 ... ]
      extract_v4_compat_subs = lib.foldlAttrs (
        acc: type: subs:
        acc ++ lib.optionals (type != "AAAA") (gen_ptr_targets subs)
      ) [ ];

      mk_host_octet = v4: builtins.head (dns.lib.mkIPv4ReverseRecord' depth v4);
    in
    lib.concatMapAttrs (
      _: host:
      lib.optionalAttrs (host ? ${nicName}) {
        ${mk_host_octet host.${nicName}.ipv4NoCidr}.PTR = extract_v4_compat_subs host.${nicName}.subdomains;
      }
    );

  # Rewrite of the old gen_reverse_v6_records in https://github.com/NixOS/nixpkgs/pull/522745
  mkIPv6ReverseRecords =
    depth: nicName:
    let
      # { A = [ subname1 ...]; AAAA = [ subname2 ...]; } -> [ subname2 ... ]
      extract_v6_compat_subs = lib.foldlAttrs (
        acc: type: subs:
        acc ++ lib.optionals (type != "A") (gen_ptr_targets subs)
      ) [ ];

      mk_host_hex = v6: builtins.head (dns.lib.mkIPv6ReverseRecord' depth v6);
    in
    lib.concatMapAttrs (
      _: host:
      lib.optionalAttrs (host ? ${nicName}) {
        ${mk_host_hex host.${nicName}.ipv6NoCidr}.PTR = extract_v6_compat_subs host.${nicName}.subdomains;
      }
    );
in
{
  # Example 100.in-addr.arpa.zone
  # $ORIGIN 100.in-addr.arpa.
  # $TTL 1d
  # @ IN SOA ns1.proteus.eu.org. sudaku233.outlook.com. (2026062300 1h 15m 1w 1d)
  # ; Nameserver definitions
  # @ IN NS ns1.proteus.eu.org.

  # ; PTR Records
  # 22.227.89 IN PTR Proteus-Desktop.proteus.eu.org.
  # 22.227.89 IN PTR proteus.eu.org.
  # 22.227.89 IN PTR ns1.proteus.eu.org.

  # 22.227.89 IN PTR algo-archive.proteus.eu.org.
  # 22.227.89 IN PTR aria2.proteus.eu.org.
  # 22.227.89 IN PTR atuin.proteus.eu.org.
  # 22.227.89 IN PTR auth.proteus.eu.org.
  # 22.227.89 IN PTR cockpit-desktop.proteus.eu.org.
  # 22.227.89 IN PTR garage.proteus.eu.org.
  # 22.227.89 IN PTR git.proteus.eu.org.
  # 22.227.89 IN PTR hass.proteus.eu.org.
  # 22.227.89 IN PTR ldap.proteus.eu.org.
  # 22.227.89 IN PTR monero.proteus.eu.org.
  # 22.227.89 IN PTR navidrome.proteus.eu.org.
  # 22.227.89 IN PTR nextcloud.proteus.eu.org.
  # 22.227.89 IN PTR niks3.proteus.eu.org.
  # 22.227.89 IN PTR nixos-search.proteus.eu.org.
  # 22.227.89 IN PTR noogle.proteus.eu.org.
  # 22.227.89 IN PTR notebook.proteus.eu.org.
  # 22.227.89 IN PTR opensearch-dashboards.proteus.eu.org.
  # 22.227.89 IN PTR papra.proteus.eu.org.
  # 22.227.89 IN PTR plane.proteus.eu.org.
  # 22.227.89 IN PTR postgresql.proteus.eu.org.
  # 22.227.89 IN PTR ql.proteus.eu.org.
  # 22.227.89 IN PTR s3.proteus.eu.org.
  # 22.227.89 IN PTR s3-pub.proteus.eu.org.
  # 22.227.89 IN PTR sb-desktop.proteus.eu.org.
  # 22.227.89 IN PTR syncthing-desktop.proteus.eu.org.
  # 22.227.89 IN PTR traefik-desktop.proteus.eu.org.
  # 22.227.89 IN PTR prometheus.proteus.eu.org.
  # 39.17.95 IN PTR Proteus-MBP14M4P.proteus.eu.org.
  # 20.161.64 IN PTR Proteus-NUC.proteus.eu.org.
  # 20.161.64 IN PTR immich.proteus.eu.org.
  # 20.161.64 IN PTR jellyfin.proteus.eu.org.
  # 20.161.64 IN PTR paperless.proteus.eu.org.
  # 20.161.64 IN PTR sb-nuc.proteus.eu.org.
  # 20.161.64 IN PTR sunshine.proteus.eu.org.
  # 20.161.64 IN PTR syncthing-nuc.proteus.eu.org.
  # 20.161.64 IN PTR traefik-nuc.proteus.eu.org.
  # 16.75.68 IN PTR Proteus-NixOS-0.proteus.eu.org.
  # 98.95.121 IN PTR Proteus-NixOS-1.proteus.eu.org.
  # 50.150.78 IN PTR Proteus-NixOS-2.proteus.eu.org.
  # 94.250.113 IN PTR Proteus-NixOS-3.proteus.eu.org.
  # 118.72.118 IN PTR Proteus-NixOS-4.proteus.eu.org.
  # 8.238.90 IN PTR Proteus-NixOS-5.proteus.eu.org.
  #
  # Example 100.in-addr.arpa.zone
  # $ORIGIN 0.e.1.a.c.5.1.1.a.7.d.f.ip6.arpa.
  # $TTL 1d
  # @ IN SOA ns1.proteus.eu.org. sudaku233.outlook.com. (2026062300 1h 15m 1w 1d)
  # ; Nameserver definitions
  # @ IN NS ns1.proteus.eu.org.

  # ; PTR Records
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR Proteus-Desktop.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR ns1.proteus.eu.org.

  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR algo-archive.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR aria2.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR atuin.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR auth.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR cockpit-desktop.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR garage.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR git.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR hass.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR ldap.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR monero.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR navidrome.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR nextcloud.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR niks3.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR nixos-search.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR noogle.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR notebook.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR opensearch-dashboards.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR papra.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR plane.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR postgresql.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR ql.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR s3.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR s3-pub.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR sb-desktop.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR syncthing-desktop.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR traefik-desktop.proteus.eu.org.
  # 8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR prometheus.proteus.eu.org.
  # 7.2.1.1.a.3.8.7.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR Proteus-MBP14M4P.proteus.eu.org.
  # 4.1.1.a.a.3.d.c.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR Proteus-NUC.proteus.eu.org.
  # 4.1.1.a.a.3.d.c.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR immich.proteus.eu.org.
  # 4.1.1.a.a.3.d.c.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR jellyfin.proteus.eu.org.
  # 4.1.1.a.a.3.d.c.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR paperless.proteus.eu.org.
  # 4.1.1.a.a.3.d.c.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR sb-nuc.proteus.eu.org.
  # 4.1.1.a.a.3.d.c.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR sunshine.proteus.eu.org.
  # 4.1.1.a.a.3.d.c.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR syncthing-nuc.proteus.eu.org.
  # 4.1.1.a.a.3.d.c.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR traefik-nuc.proteus.eu.org.
  # 5.5.d.a.a.3.8.6.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR Proteus-NixOS-0.proteus.eu.org.
  # 2.6.f.5.a.3.f.d.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR Proteus-NixOS-1.proteus.eu.org.
  # 2.3.6.9.a.3.2.8.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR Proteus-NixOS-2.proteus.eu.org.
  # e.5.a.f.a.3.0.7.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR Proteus-NixOS-3.proteus.eu.org.
  # 6.7.8.4.a.3.3.e.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR Proteus-NixOS-4.proteus.eu.org.
  # 8.0.e.e.a.3.5.c.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR Proteus-NixOS-5.proteus.eu.org.

  # TODO: extract v4 octets and v6 hexes with v4PrefixLen and v6PrefixLen
  # TODO: improve
  # https://github.com/nix-community/dns.nix/blob/a97cf4156e9f044fe4bed5be531061000dfabb07/dns/util/default.nix
  vars.hostAddrs =
    let
      regHost = true;
    in
    {
      # ============================================
      # Homelab's Physical Machines (TODO: Try KubeVirt)
      # ============================================
      Proteus-MBP14M4P = {
        tailscale = {
          inherit regHost;
          ipv4 = "100.95.17.39/10";
          ipv6 = "fd7a:115c:a1e0::783a:1127/48";
        };
        easytier = {
          inherit regHost;
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
            inherit regHost;
            ipv4 = "100.64.161.20/10";
            ipv6 = "fd7a:115c:a1e0::cd3a:a114/48";
            subdomains = {
              A = subs;
              AAAA = subs;
            };
          };
          easytier = {
            inherit regHost;
            ipv4 = "10.0.0.2/24";
            ipv6 = "fdfe:dcba:9877::2/64";
            subdomains = {
              A = subs;
              AAAA = subs;
            };
          };
          wire.name = "enp46s0";
        };
      Proteus-Desktop =
        let
          subdomains =
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
            inherit regHost;
            ipv4 = "100.89.227.22/10";
            ipv6 = "fd7a:115c:a1e0::1a01:e318/48";
            subdomains = subdomains;
          };
          easytier = {
            inherit regHost;
            ipv4 = "10.0.0.3/24";
            ipv6 = "fdfe:dcba:9877::3/64";
            inherit subdomains;
          };
          wire.name = "enp4s0";
          wireless = {
            name = "wlp0s20u9";
            ipv4 = "192.168.12.1/24";
          };
        };
      # ============================================
      # Other VMs and Physical Machines
      # ============================================
      Proteus-NixOS-0 = {
        tailscale = {
          inherit regHost;
          ipv4 = "100.68.75.16";
          ipv6 = "fd7a:115c:a1e0::683a:ad55";
        };
        easytier = {
          inherit regHost;
          ipv4 = "10.0.0.1";
          ipv6 = "fdfe:dcba:9877::1";
        };
      };
      Proteus-NixOS-1 = {
        tailscale = {
          inherit regHost;
          ipv4 = "100.121.95.98";
          ipv6 = "fd7a:115c:a1e0::df3a:5f62";
        };
        easytier = {
          inherit regHost;
          ipv4 = "10.0.0.5";
          ipv6 = "fdfe:dcba:9877::5";
        };
      };
      Proteus-NixOS-2 = {
        tailscale = {
          inherit regHost;
          ipv4 = "100.78.150.50";
          ipv6 = "fd7a:115c:a1e0::823a:9632";
        };
        easytier = {
          inherit regHost;
          ipv4 = "10.0.0.6";
          ipv6 = "fdfe:dcba:9877::6";
        };
      };
      Proteus-NixOS-3 = {
        tailscale = {
          inherit regHost;
          ipv4 = "100.113.250.94";
          ipv6 = "fd7a:115c:a1e0::703a:fa5e";
        };
        easytier = {
          inherit regHost;
          ipv4 = "10.0.0.7";
          ipv6 = "fdfe:dcba:9877::7";
        };
      };
      Proteus-NixOS-4 = {
        tailscale = {
          inherit regHost;
          ipv4 = "100.118.72.118";
          ipv6 = "fd7a:115c:a1e0::e33a:4876";
        };
        easytier = {
          inherit regHost;
          ipv4 = "10.0.0.8";
          ipv6 = "fdfe:dcba:9877::8";
        };
      };
      Proteus-NixOS-5 = {
        tailscale = {
          inherit regHost;
          ipv4 = "100.90.238.8";
          ipv6 = "fd7a:115c:a1e0::c53a:ee08";
        };
        easytier = {
          inherit regHost;
          ipv4 = "10.0.0.9";
          ipv6 = "fdfe:dcba:9877::9";
        };
      };
      Proteus-VF2.wire.ipv4 = "192.168.1.26";
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

    # Access-control of what networks are allowed for recursive queries
    # cacheNetworks = [
    #   "127.0.0.0/8" "::1/128"
    #   "100.64.0.0/10" "fd7a:115c:a1e0::/48"
    #   "192.168.0.0/16"
    # ];
    cacheNetworks = [ "none" ]; # Do not allow access to cache

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
      # Strictly Authoritative-Only Mode, implies 'empty-zones-enable no', as empty zones would shadow my overlay
      # network's IP
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
      # Who can perform dynamic DNS updates (add/remove records on the fly).
      allow-update { none; };

      server-id none;
    '';
    zones =
      let
        shared_zone_cfg = {
          master = true;
          # Apply the DNSSEC policy to sign the zone locally
          # extraConfig = "dnssec-policy custom;";
        };
        mk_ipv4_reverse_zone =
          depth: nic_name:
          let
            name = "${
              lib.last (dns.lib.mkIPv4ReverseRecord' depth config.vars.hostAddrs.Proteus-NUC.${nic_name}.ipv4NoCidr)
            }.in-addr.arpa";
          in
          shared_zone_cfg
          // {
            inherit name;
            file =
              # dns.lib.toString
              writeZone name (shared_head_cfg // { subdomains = mkIPv4ReverseRecords depth nic_name config.vars.hostAddrs; });
          };

        mk_ipv6_reverse_zone =
          depth: nic_name:
          let
            name = "${
              lib.last (dns.lib.mkIPv6ReverseRecord' depth config.vars.hostAddrs.Proteus-NUC.${nic_name}.ipv6NoCidr)
            }.ip6.arpa";
          in
          shared_zone_cfg
          // {
            inherit name;
            file =
              # dns.lib.toString
              writeZone name (shared_head_cfg // { subdomains = mkIPv6ReverseRecords depth nic_name config.vars.hostAddrs; });
          };
      in
      {
        ${const.domain} = shared_zone_cfg // {
          file = writeZone const.domain (
            shared_head_cfg // { subdomains = lib.mkMerge (mkSubdomainRecords config.vars.hostAddrs); }
          );
        };
        reverse_v4_et = mk_ipv4_reverse_zone 1 "tailscale";
        reverse_v4_ts = mk_ipv4_reverse_zone 3 "easytier";
        reverse_v6_et = mk_ipv6_reverse_zone (48 / 4) "tailscale";
        reverse_v6_ts = mk_ipv6_reverse_zone (64 / 4) "easytier";
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
}
