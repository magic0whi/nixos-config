{
  config,
  lib,
  myvars,
  pkgs,
  ...
}: let
  ## BEGIN Variables
  soa_parms = {
    serial = "2026051809"; # Serial (YYYYMMDDNN)
    refresh = "3600"; # Refresh (1 hour)
    retry = "1800"; # Retry (30 minutes)
    expire = "604800"; # Expire (1 week)
    minimal_ttl = "86400"; # Minimum TTL
  };
  zone_head = _domain: ''
    $ORIGIN ${_domain}.
    $TTL ${soa_parms.minimal_ttl}
    @ IN SOA  ns1.${myvars.domain}. admin.${myvars.domain}. (
              ${soa_parms.serial}       ; Serial (YYYYMMDDNN)
              ${soa_parms.refresh}      ; Refresh (1 hour)
              ${soa_parms.retry}        ; Retry (30 minutes)
              ${soa_parms.expire}       ; Expire (1 week)
              ${soa_parms.minimal_ttl}) ; Minimum TTL
    ; Nameserver definitions
    @ IN NS   ns1.${myvars.domain}.
  '';
  ts_depth = 1;
  et_depth = 3;
  ts_prefix_len = 48;
  et_prefix_len = 48;
  ## END Variables
  ## BEGIN Functions
  # Usage example
  # exextract_attr_to "et_ipv4" "ipv4" {Proteus-NUC = {et_ipv4 = "10.0.0.2";};}
  # => {Proteus-NUC = {ipv4 = "10.0.0.2";};}
  rename_attr_to = src_attr: dest_attr: hosts:
    builtins.mapAttrs (_: v: v // {${dest_attr} = v.${src_attr};}) (lib.filterAttrs (_: v: v ? ${src_attr}) hosts);

  # Usage example
  # gen_v4_records "et" {Proteus-Desktop = {ipv4 = "10.0.0.3";}; Proteus-NUC = {ipv4 = "10.0.0.2";};}
  # => ''
  # Proteus-Desktop.et IN A 10.0.0.3
  # Proteus-NUC.et IN A 10.0.0.2
  # ''
  gen_v4_records = suffix:
    lib.foldlAttrs (acc: hostname: v: (lib.concatStrings [
      "${lib.optionalString (acc != "") "${acc}\n"}" # Accumulation
      "${hostname}${lib.optionalString (suffix != "") ".${suffix}"}" # Subdomain
      " IN A ${v.ipv4}"
    ]))
    "";
  gen_v6_records = suffix:
    lib.foldlAttrs (acc: hostname: v: (lib.concatStrings [
      "${lib.optionalString (acc != "") "${acc}\n"}" # Accumulation
      "${hostname}${lib.optionalString (suffix != "") ".${suffix}"}" # Subdomain
      " IN AAAA ${v.ipv6}"
    ]))
    "";

  # Usage example
  # gen_subdomain_records {Proteus-Desktop = {domains.CNAME = ["garage"]}; Proteus-NUC = {domains = {A = ["@" "ns1"]; AAAA = ["@" "ns1"]; CNAME = ["aria2"]}; ipv4 = "100.64.161.20"; ipv6 = "fd7a:115c:a1e0::cd3a:a114";}
  # => ''
  # garage IN CNAME Proteus-Desktop
  # @ IN A 100.64.161.20
  # ns1 IN A 100.64.161.20
  # @ IN AAAA fd7a:115c:a1e0::cd3a:a114
  # ns1 IN AAAA fd7a:115c:a1e0::cd3a:a114
  # aria2 IN CNAME Proteus-NUC
  # ''
  gen_subdomain_records = hosts:
    lib.concatLines (
      lib.foldlAttrs (acc_1: hostname: host_val:
        acc_1
        ++ (
          lib.foldlAttrs (acc_2: type: subs:
            acc_2
            ++ (map (sub: "${sub} IN ${type} ${
                if type == "A"
                then host_val.ipv4
                else if type == "AAAA"
                then host_val.ipv6
                else if type == "CNAME"
                then hostname
                else throw "Unsupported record type ${type}"
              }")
              subs))
          []
          host_val.domains
        ))
      []
      hosts
    );

  # Usage example
  # gen_reverse_v4_records 1 "proteus.eu.org" {Proteus-Desktop = {domains.CNAME = ["garage"] ipv4 = "100.89.227.22";}; Proteus-NUC = {domains = {A = ["@" "ns1"]; AAAA = ["ns1" "v6"]; CNAME = ["aria2"]}; ipv4 = "100.64.161.20";}
  # => {
  #   "100" = ''
  #     22.227.89 IN PTR Proteus-Desktop.proteus.eu.org.
  #     22.227.89 IN PTR garage.proteus.eu.org.
  #
  #
  #     20.161.64 IN PTR Proteus-NUC.proteus.eu.org.
  #     20.161.64 IN PTR proteus.eu.org.
  #     20.161.64 IN PTR ns1.proteus.eu.org.
  #     20.161.64 IN PTR aria2.proteus.eu.org.
  #   '';
  # }
  gen_reverse_v4_records = depth: domain: hosts:
    lib.foldlAttrs
    (acc: hostname: host_val:
      lib.recursiveUpdate acc (let
        splited_ipv4 = lib.splitString "." host_val.ipv4;
        prefix = builtins.concatStringsSep "." (lib.reverseList (lib.take depth splited_ipv4));
        host_octets = builtins.concatStringsSep "." (lib.reverseList (lib.drop depth splited_ipv4));
      in {
        ${prefix} = ''
          ${
            lib.optionalString (acc ? ${prefix}) "${acc.${prefix}}\n"
          }${host_octets} IN PTR ${hostname}.${domain}.
          ${
            lib.optionalString (host_val ? domains) (let
              records =
                lib.foldlAttrs (acc: type: subs:
                  acc
                  ++ lib.optionals (type != "AAAA") (map (sub:
                    lib.optionalString (!lib.hasInfix "*" sub) "${host_octets} IN PTR ${
                      if sub != "@"
                      then "${sub}.${domain}."
                      else "${domain}."
                    }")
                  subs))
                []
                host_val.domains;
            in (lib.concatLines (lib.unique records)))
          }
        '';
      })) {}
    hosts;

  # Usage example
  # gen_reverse_v6_records 48 "proteus.eu.org" {Proteus-Desktop = {domains.CNAME = ["garage"] ipv6 = "fd7a:115c:a1e0::1a01:e318";}; Proteus-NUC = {domains = {A = ["ns1" "v4"]; AAAA = ["@" "ns1"]; CNAME = ["aria2"]}; ipv6 = "fd7a:115c:a1e0::cd3a:a114";}
  # => {
  #   "0.e.1.a.c.5.1.1.a.7.d.f" = ''
  #     8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR Proteus-Desktop.proteus.eu.org.
  #     8.1.3.e.1.0.a.1.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR garage.proteus.eu.org.
  #
  #
  #     4.1.1.a.a.3.d.c.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR Proteus-NUC.proteus.eu.org.
  #     4.1.1.a.a.3.d.c.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR proteus.eu.org.
  #     4.1.1.a.a.3.d.c.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR ns1.proteus.eu.org.
  #     4.1.1.a.a.3.d.c.0.0.0.0.0.0.0.0.0.0.0.0 IN PTR aria2.proteus.eu.org.
  #   '';
  # }
  gen_reverse_v6_records = prefix_len: domain: hosts:
    lib.foldlAttrs
    (acc: hostname: host_val:
      lib.recursiveUpdate acc (let
        # ==========================================
        # IPv6 Reverse Logic (Zero-Compression Expansion)
        # ==========================================
        # 1. Split by "::" to handle zero-compression
        # e.g., "fd7a:115c:a1e0::cd3a:a114" -> ["fd7a:115c:a1e0" "cd3a:a114"]
        split_double_colon = lib.splitString "::" host_val.ipv6;

        # 2. Split the IP into a list, and pad add segments to 4 characters
        # e.g., Left part: ["fd7a" "115c" "a1e0"], right part: ["cd3a" "a114"]
        pad_hex = s: let
          len = builtins.stringLength s;
        in
          # Helper: Pad a string to 4 characters with leading zeros
          if len == 0
          then "0000"
          else if len == 1
          then "000${s}"
          else if len == 2
          then "00${s}"
          else if len == 3
          then "0${s}"
          else s;
        left_padded = map pad_hex (lib.splitString ":" (builtins.head split_double_colon));
        right_padded = map pad_hex (lib.splitString ":" (lib.last split_double_colon));

        # 3. Calculate and generate missing zero segments (IPv6 has 8 total segments)
        # e.g., Missing count is `8 - (3 + 2) = 3`, so the missing_segments is: ["0000" "0000" "0000"]
        missing_segments =
          builtins.genList (_: "0000") (8 - (builtins.length left_padded + builtins.length right_padded));

        # 4. Construct the full 32-character string, iterate to break it to chars list, them reverse it
        # e.g., ["fd7a" "115c" "a1e0" "0000" "0000" "0000" "cd3a" "a114"]
        # -> ["f" "d" "7" "a" "1" "1" "5" "c" "a" "1" "e" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "c" "d" "3" "a" "a" "1" "1" "4"]
        # -> ["4" "1" "1" "a" "a" "3" "d" "c" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "e" "1" "a" "c" "5" "1" "1" "a" "7" "d" "f"]
        formated_ipv6 = lib.reverseList (lib.concatMap lib.stringToCharacters (left_padded ++ missing_segments ++ right_padded));

        # Tailscale uses a /48 prefix. So the PTR length is `128 - 48 = 80` bits (20 hex chars), and the Zone Prefix is 48
        # ["4" "1" "1" "a" "a" "3" "d" "c" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "e" "1" "a" "c" "5" "1" "1" "a" "7" "d" "f"]
        # -> ["4" "1" "1" "a" "a" "3" "d" "c" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0"]
        # -> "4.1.1.a.a.3.d.c.0.0.0.0.0.0.0.0.0.0.0.0"
        host_hexes = builtins.concatStringsSep "." (lib.take ((128 - prefix_len) / 4) formated_ipv6);
        prefix = builtins.concatStringsSep "." (lib.drop ((128 - prefix_len) / 4) formated_ipv6);
      in {
        "${prefix}" = ''
          ${
            lib.optionalString (acc ? ${prefix}) "${acc.${prefix}}\n"
          }${host_hexes} IN PTR ${hostname}.${domain}.
          ${
            lib.optionalString (host_val ? domains) (let
              records =
                lib.foldlAttrs (acc: type: subs:
                  acc
                  ++ lib.optionals (type != "A") (map (sub:
                    lib.optionalString (!lib.hasInfix "*" sub) "${host_hexes} IN PTR ${
                      if sub != "@"
                      then "${sub}.${domain}."
                      else "${domain}."
                    }")
                  subs))
                []
                host_val.domains;
            in (lib.concatLines (lib.unique records)))
          }
        '';
      })) {}
    hosts;
  ## END Functions
  # =========================================
  # Forward Zone (proteus.eu.org)
  # =========================================
  proteus_zone = pkgs.writeText "${myvars.domain}.zone" ((zone_head myvars.domain)
    + ''
      ; Grouped Host Records - IPv4
      ${gen_v4_records "" (lib.filterAttrs (_: v: v ? ipv4) myvars.networking.hosts_addr)}
      ${gen_v4_records "" (rename_attr_to "et_ipv4" "ipv4" myvars.networking.hosts_addr)}

      ; Grouped Host Records - IPv6
      ${gen_v6_records "" (lib.filterAttrs (_: v: v ? ipv6) myvars.networking.hosts_addr)}
      ${gen_v6_records "" (rename_attr_to "et_ipv6" "ipv6" myvars.networking.hosts_addr)}

      ; Grouped Host Records - Explicit EasyTier IPv4
      ${gen_v4_records "et" (rename_attr_to "et_ipv4" "ipv4" myvars.networking.hosts_addr)}

      ; Grouped Host Records - Explicit EasyTier IPv6
      ${gen_v6_records "et" (rename_attr_to "et_ipv6" "ipv6" myvars.networking.hosts_addr)}

      ; Subdomain Services
      ${gen_subdomain_records (lib.filterAttrs (_: v: v ? domains) myvars.networking.hosts_addr)}

      ${gen_subdomain_records (lib.filterAttrs (_: v: v ? domains)
        (builtins.mapAttrs
          (_: host_val:
            host_val
            // (lib.optionalAttrs (host_val ? domains) {
              domains =
                builtins.mapAttrs
                # Remove "@" in A and AAAA
                (_: records: lib.remove "@" records)
                (builtins.removeAttrs host_val.domains ["CNAME"]);
            }))
          (rename_attr_to "et_ipv6" "ipv6" (rename_attr_to "et_ipv4" "ipv4" myvars.networking.hosts_addr))))}
    '');
  # =========================================
  # IPv4 Reverse Zones
  # =========================================
  reverse_v4_zones_ts = builtins.mapAttrs (prefix: records:
    pkgs.writeText "${prefix}.in-addr.arpa.zone" ''
      ${zone_head "${prefix}.in-addr.arpa"}
      ; PTR Records
      ${records}
    '')
  (gen_reverse_v4_records ts_depth myvars.domain (lib.filterAttrs (_: v: v ? ipv4) myvars.networking.hosts_addr));
  reverse_v4_zones_et = builtins.mapAttrs (prefix: records:
    pkgs.writeText "${prefix}.in-addr.arpa.zone" ''
      ${zone_head "${prefix}.in-addr.arpa"}
      ; PTR Records
      ${records}
    '')
  (gen_reverse_v4_records et_depth myvars.domain (rename_attr_to "et_ipv4" "ipv4" myvars.networking.hosts_addr));

  # =========================================
  # IPv6 Reverse Zone
  # =========================================
  reverse_v6_zones_ts =
    builtins.mapAttrs (prefix: records:
      pkgs.writeText "${prefix}.ip6.arpa.zone" ''
        ${zone_head "${prefix}.ip6.arpa"}
        ; PTR Records
        ${records}
      '')
    (gen_reverse_v6_records ts_prefix_len myvars.domain
      (lib.filterAttrs (_: v: v ? ipv6) myvars.networking.hosts_addr));
  reverse_v6_zones_et = builtins.mapAttrs (prefix: records:
    pkgs.writeText "${prefix}.ip6.arpa.zone" ''
      ${zone_head "${prefix}.ip6.arpa"}
      ; PTR Records
      ${records}
    '')
  (gen_reverse_v6_records et_prefix_len myvars.domain (rename_attr_to "et_ipv6" "ipv6" myvars.networking.hosts_addr));
in {
  networking.firewall = {
    allowedTCPPorts = [53];
    allowedUDPPorts = [53];
  };
  systemd.services.bind.preStart = lib.mkAfter ''
    install -m 0644 ${proteus_zone} ${config.services.bind.directory}/${proteus_zone.name}
    ${
      lib.concatLines (lib.mapAttrsToList
        (_: zone_file: "install -m 0644 ${zone_file} ${config.services.bind.directory}/${zone_file.name}")
        reverse_v4_zones_ts)
    }
    ${
      lib.concatLines (lib.mapAttrsToList
        (_: zone_file: "install -m 0644 ${zone_file} ${config.services.bind.directory}/${zone_file.name}")
        reverse_v4_zones_et)
    }
    ${
      lib.concatLines (lib.mapAttrsToList
        (_: zone_file: "install -m 0644 ${zone_file} ${config.services.bind.directory}/${zone_file.name}")
        reverse_v6_zones_ts)
    }
    ${
      lib.concatLines (lib.mapAttrsToList
        (_: zone_file: "install -m 0644 ${zone_file} ${config.services.bind.directory}/${zone_file.name}")
        reverse_v6_zones_et)
    }
  '';
  services.resolved.settings.Resolve = {
    DNSSEC = "allow-downgrade";
    Domains =
      [
        "~${myvars.domain}" # The '~' prefix makes this a routing domain
      ]
      ++ (map (zone_file: "~${lib.removeSuffix ".zone" zone_file.name}") (builtins.attrValues reverse_v4_zones_ts))
      ++ (map (zone_file: "~${lib.removeSuffix ".zone" zone_file.name}") (builtins.attrValues reverse_v4_zones_et))
      ++ (map (zone_file: "~${lib.removeSuffix ".zone" zone_file.name}") (builtins.attrValues reverse_v6_zones_ts))
      ++ (map (zone_file: "~${lib.removeSuffix ".zone" zone_file.name}") (builtins.attrValues reverse_v6_zones_et));

    DNS = ["${myvars.networking.hosts_addr.Proteus-NUC.ipv4}#${myvars.domain}"];
  };
  # Trust Island
  # NOTE: Query the zone apex (`proteus.eu.org`, `161.64.100.in-addr.arpa`
  # `0.e.1.a.c.5.1.1.a.7.d.f.ip6.arpa`)
  # nix run nixpkgs#dig -- @100.64.161.20 161.64.100.in-addr.arpa DNSKEY +noall +answer | nix shell nixpkgs#bind --command dnssec-dsfromkey -f - 161.64.100.in-addr.arpa
  # Or
  # nix run nixpkgs#dig -- @100.64.161.20 161.64.100.in-addr.arpa DNSKEY +noall +answer | nix shell nixpkgs#ldns.examples --command ldns-key2ds -n /dev/stdin
  environment.etc."dnssec-trust-anchors.d/${myvars.domain}.positive".text = ''
    ${myvars.domain}. IN DS 19905 15 2 AC53E45BD2ECD7E4D8DED050FB08E0F37095AF97E0B6F73CE912A56CE5C542C0
  '';
  # environment.etc."dnssec-trust-anchors.d/${lib.removeSuffix ".zone" reverse_v4_zones."100".name}.positive".text = ''
  #   ${lib.removeSuffix ".zone" reverse_v4_zones."100".name}. IN DS 32237 15 2 5F089BE41C87322212B05BAB4A760097235220F5346A1F51F6161728B77A0F8F
  # '';
  # environment.etc."dnssec-trust-anchors.d/${lib.removeSuffix ".zone" reverse_v4_zones."192".name}.positive".text = ''
  #   ${lib.removeSuffix ".zone" reverse_v4_zones."192".name}. IN DS 25153 15 2 B5B5AC75FDCC85AACBDF747323AC5F7CA8D8FC482D03C848DEE4EFAD79F7CD50
  # '';
  environment.etc."dnssec-trust-anchors.d/${lib.removeSuffix ".zone" reverse_v6_zones_ts."0.e.1.a.c.5.1.1.a.7.d.f".name}.positive".text = ''
    ${lib.removeSuffix ".zone" reverse_v6_zones_ts."0.e.1.a.c.5.1.1.a.7.d.f".name}. IN DS 60960 15 2 DD09A9E95F7C7851FAC65FD39FDE55FAB2C001D5B37D744F98AA23C56FD63D16
  '';
  services.bind = {
    enable = true;
    checkConfig = false;
    # Persistent directory for DNSSEC key states.
    # NixOS defaults to /run/named, which clears on reboot.
    directory = "/srv/bind";
    # Access-control of what networks are allowed for recursive queries
    # cacheNetworks = [
    #   "127.0.0.0/8" "::1/128"
    #   "100.64.0.0/10" "fd7a:115c:a1e0::/48"
    #   "192.168.0.0/16"
    # ];
    forwarders = [];
    # Bind standard port 53 strictly to the specific interface IPs
    listenOn = with myvars.networking.hosts_addr.Proteus-NUC; ["127.0.0.1" ipv4 et_ipv4];
    listenOnIpv6 = with myvars.networking.hosts_addr.Proteus-NUC; ["::1" ipv6 et_ipv4];

    # Inject the variables into the raw extraOptions string for DoT and DoH
    extraOptions = ''
      # Strictly Authoritative-Only Mode
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
    zones =
      {
        ${myvars.domain} = {
          master = true;
          file = proteus_zone.name; # Relative path
          # Apply the DNSSEC policy to sign the zone locally
          extraConfig = "dnssec-policy custom;";
        };
      }
      // (lib.foldlAttrs (
          acc: _: zone_file:
            acc
            // {
              ${lib.removeSuffix ".zone" zone_file.name} = {
                master = true;
                file = zone_file.name;
                extraConfig = "dnssec-policy custom;";
              };
            }
        ) {}
        reverse_v4_zones_ts)
      // (lib.foldlAttrs (
          acc: _: zone_file:
            acc
            // {
              ${lib.removeSuffix ".zone" zone_file.name} = {
                master = true;
                file = zone_file.name;
                extraConfig = "dnssec-policy custom;";
              };
            }
        ) {}
        reverse_v4_zones_et)
      // (lib.foldlAttrs (
          acc: _: zone_file:
            acc
            // {
              ${lib.removeSuffix ".zone" zone_file.name} = {
                master = true;
                file = zone_file.name;
                extraConfig = "dnssec-policy custom;";
              };
            }
        ) {}
        reverse_v6_zones_ts)
      // (lib.foldlAttrs (
          acc: _: zone_file:
            acc
            // {
              ${lib.removeSuffix ".zone" zone_file.name} = {
                master = true;
                file = zone_file.name;
                extraConfig = "dnssec-policy custom;";
              };
            }
        ) {}
        reverse_v6_zones_et);
  };
}
