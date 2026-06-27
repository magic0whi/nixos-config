{
  config,
  lib,
  const,
  dns,
  pkgs,
  ...
}:
let
  hostname = config.networking.hostName;
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
  networking.firewall = {
    allowedTCPPorts = [
      53
      853
    ];
    allowedUDPPorts = [ 53 ]; # Bind don't support DNS-over QUIC
  };
  services.bind =
    let
      nics = config.vars.hostAddrs.${hostname};
    in
    {
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
        nics.easytier.ipv4NoCidr
        nics.tailscale.ipv4NoCidr
      ];
      listenOnIpv6 = [
        "::1"
        nics.easytier.ipv6NoCidr
        nics.tailscale.ipv6NoCidr
      ];
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
                lib.last (dns.lib.mkIPv4ReverseRecord' depth const.networking.allHostAddrs.${hostname}.${nic_name}.ipv4NoCidr)
              }.in-addr.arpa";
            in
            shared_zone_cfg
            // {
              inherit name;
              file =
                # dns.lib.toString
                writeZone name (shared_head_cfg // { subdomains = mkIPv4ReverseRecords depth nic_name const.networking.allHostAddrs; });
            };

          mk_ipv6_reverse_zone =
            depth: nic_name:
            let
              name = "${
                lib.last (dns.lib.mkIPv6ReverseRecord' depth config.vars.hostAddrs.${hostname}.${nic_name}.ipv6NoCidr)
              }.ip6.arpa";
            in
            shared_zone_cfg
            // {
              inherit name;
              file =
                # dns.lib.toString
                writeZone name (shared_head_cfg // { subdomains = mkIPv6ReverseRecords depth nic_name const.networking.allHostAddrs; });
            };
        in
        {
          ${const.domain} = shared_zone_cfg // {
            file = writeZone const.domain (
              shared_head_cfg // { subdomains = lib.mkMerge (mkSubdomainRecords const.networking.allHostAddrs); }
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
            " || Host(`${hostname}.${const.tailnet}`)"
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
